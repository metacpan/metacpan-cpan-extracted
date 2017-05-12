package Authen::CAS::UserAgent;

=head1 NAME

Authen::CAS::UserAgent - CAS-aware LWP::UserAgent

=head1 SYNOPSIS

 use Authen::CAS::UserAgent;

 my $ua = Authen::CAS::UserAgent->new(
   'cas_opts' => {
     'server' => 'https://cas.example.com/cas/',
     'username' => 'user',
     'password' => 'password',
     'restful'  => 1,
   },
 );
 $ua->get('https://www.example.com/casProtectedResource');

=head1 DESCRIPTION

This module attempts to add transparent CAS authentication support to
LWP::UserAgent. It currently supports using proxy granting tickets, the RESTful
API, screen scraping the login screen, or a custom login callback when CAS
authentication is required.

=cut

use strict;
use utf8;
use base qw{LWP::UserAgent Exporter};

our $VERSION = '0.91';

use constant CASHANDLERNAME => __PACKAGE__ . '.Handler';
use constant XMLNS_CAS => 'http://www.yale.edu/tp/cas';

use constant ERROR_PROXY_INVALIDRESPONSE => 1;
use constant ERROR_PROXY_INVALIDTICKET   => 2;
use constant ERROR_PROXY_UNKNOWN         => 3;

our @EXPORT_OK = qw{
	ERROR_PROXY_INVALIDRESPONSE
	ERROR_PROXY_INVALIDTICKET
	ERROR_PROXY_UNKNOWN
};
our %EXPORT_TAGS = (
	ERRORS => [qw{
		ERROR_PROXY_INVALIDRESPONSE
		ERROR_PROXY_INVALIDTICKET
		ERROR_PROXY_UNKNOWN
	}],
);

use HTTP::Request;
use HTTP::Request::Common ();
use HTTP::Status ();
use URI;
use URI::Escape qw{uri_escape};
use URI::QueryParam;
use XML::LibXML;
use XML::LibXML::XPathContext;

##LWP handlers

#cas login handler, detects a redirect to the cas login page, logs the user in and updates the initial redirect
my $casLoginHandler = sub {
	my ($response, $ua, $h) = @_;

	#prevent potential recursion caused by attempting to log the user in
	return if($h->{'running'} > 0);

	#check to see if this is a redirection to the login page
	my $uri = URI->new_abs($response->header('Location'), $response->request->uri)->canonical;
	my $loginUri = URI->new_abs('login', $h->{'casServer'})->canonical;
	if(
		$uri->scheme eq $loginUri->scheme &&
		$uri->authority eq $loginUri->authority &&
		$uri->path eq $loginUri->path
	) {
		#short-circuit if a service isn't specified
		my $service = URI->new(scalar $uri->query_param('service'));
		return if($service eq '');

		#short-circuit if in strict mode and the service is different than the original uri
		return if($h->{'strict'} && $response->request->uri ne $service);

		#get a ticket for the specified service
		my $ticket = $ua->get_cas_ticket($service, $h);

		#short-circuit if a ticket wasn't found
		return if(!defined $ticket);

		#update the Location header
		$response->header('Location', $service . ($service =~ /\?/ ? '&' : '?') . 'ticket=' . uri_escape($ticket));

		#attach a local response_redirect handler that will issue the redirect if necessary
		push(@{$response->{'handlers'}->{'response_redirect'}},
			{
				%$h,
				'callback' => sub {
					my ($response, $ua, $h) = @_;

					#delete this response_redirect handler from the response object
					delete $response->{'handlers'}->{'response_redirect'};
					delete $response->{'handlers'} unless(%{$response->{'handlers'}});

					#determine the new uri
					my $uri = $response->request->uri;
					my $newUri = URI->new_abs(scalar $response->header('Location'), $uri);

					#check to see if the target uri is the same as the original uri (ignoring the ticket)
					my $targetUri = $newUri->clone;
					if($targetUri =~ s/[\&\?]ticket=[^\&\?]*$//sog) {
						if($targetUri eq $uri) {
							#clone the original request, update the request uri, and return the new request
							my $request = $response->request->clone;
							$request->uri($newUri);
							return $request
						}
					}

					return;
				},
			},
		);
	}

	return;
};

# default heuristic for finding login parameters
my $defaultLoginParamsHeuristic = sub {
	my ($service, $response, $ua, $h, @params) = @_;

	# find all input controls on the submit form
	my $content = $response->decoded_content;
	while($content =~ /(\<input.*?\>)/igs) {
		my $input = $1;
		my $name = $input =~ /name=\"(.*?)\"/si ? $1 : undef;
		my $value = $input =~ /value=\"(.*?)\"/si ? $1 : undef;

		# we only care about the lt, execution, and _eventId parameters
		if($name eq 'lt' || $name eq 'execution' || $name eq '_eventId') {
			push @params, $name, $value;
		}
	}

	# return the updated params
	return @params;
};

#default heuristic for detecting the service and ticket in the login response
my $defaultTicketHeuristic = sub {
	my ($response, $service) = @_;

	#attempt using the Location header on a redirect response
	if($response->is_redirect) {
		my $uri = $response->header('Location');
		if($uri =~ /[?&]ticket=([^&]*)$/) {
			return $1;
		}
	}

	#check for a javascript window.location.href redirect
	if($response->decoded_content =~ /window\.location\.href="[^"]*ticket=([^&"]*?)"/sg) {
		return $1;
	}

	return;
};

#default callback to log the user into CAS and return a ticket for the specified service
my $defaultLoginCallback = sub {
	my ($service, $ua, $h) = @_;

	# generate the params for this login request
	my $loginUri = URI->new_abs('login', $h->{'casServer'});
	my @params = (
		'service' => $service,
		'username' => $h->{'username'},
		'password' => $h->{'password'},
	);

	# find any additional required login params (i.e. lt, execution, and _eventId)
	if(@{$h->{'config'}->{'param_heuristics'}}) {
		# retrieve the login form that will be parsed by configured param_heuristics
		my $formUri = $loginUri->clone();
		$formUri->query_param('service', $service);
		my $response = $ua->simple_request(HTTP::Request::Common::GET($formUri));

		# process all configured param heuristics
		foreach (@{$h->{'config'}->{'param_heuristics'}}) {
			# skip invalid heuristics
			next if(ref($_) ne 'CODE');

			# process this heuristic
			@params = $_->($service, $response, $ua, $h, @params);
		}
	}

	# issue the login request
	my $response = $ua->simple_request(HTTP::Request::Common::POST($loginUri, \@params));

	#short-circuit if there is no response from CAS for some reason
	return if(!$response);

	#process all the ticket heuristics until a ticket is found
	foreach (@{$h->{'config'}->{'ticket_heuristics'}}) {
		#skip invalid heuristics
		next if(ref($_) ne 'CODE');

		#process the current heuristic
		my $ticket = eval {$_->($response, $service)};

		#quit processing if a ticket is found
		return $ticket if(defined $ticket);
	}

	#return undefined if no ticket was found
	return;
};

# Login callback when the specified server is in proxy mode
my $proxyLoginCallback = sub {
	my ($service, $ua, $h) = @_;

	#clear any previous error
	delete $h->{'error'};

	#create the request uri
	my $ptUri = URI->new_abs('proxy', $h->{'casServer'});
	$ptUri->query_form(
		'pgt'           => $h->{'pgt'},
		'targetService' => $service,
	);

	# fetch proxy ticket and parse response xml
	my $response = $ua->simple_request(HTTP::Request::Common::GET($ptUri));
	my $doc = eval {XML::LibXML->new()->parse_string($response->decoded_content('charset' => 'none'))};
	if($@ || !$doc) {
		$h->{'error'} = ERROR_PROXY_INVALIDRESPONSE;
		push @{$h->{'errors'}}, $h->{'error'};
		return;
	}

	# process the response to extract the proxy ticket or any errors
	my $xpc = XML::LibXML::XPathContext->new();
	$xpc->registerNs('cas', XMLNS_CAS);
	if($xpc->exists('/cas:serviceResponse/cas:proxyFailure', $doc)) {
		my $code = $xpc->findvalue('/cas:serviceResponse/cas:proxyFailure[position()=1]/@code', $doc);
		if($code eq 'INVALID_TICKET') {
			$h->{'error'} = ERROR_PROXY_INVALIDTICKET;
			push @{$h->{'errors'}}, $h->{'error'};
		}
		else {
			$h->{'error'} = ERROR_PROXY_UNKNOWN;
			push @{$h->{'errors'}}, $h->{'error'};
		}
	}
	elsif($xpc->exists('/cas:serviceResponse/cas:proxySuccess', $doc)) {
		return $xpc->findvalue('/cas:serviceResponse/cas:proxySuccess[position()=1]/cas:proxyTicket[position()=1]', $doc);
	}
	else {
		$h->{'error'} = ERROR_PROXY_INVALIDRESPONSE;
		push @{$h->{'errors'}}, $h->{'error'};
	}

	# default to no ticket being returned
	return;
};

#Login callback for CAS servers that implement the RESTful API
#TODO: cache the TGT
my $restLoginCallback = sub {
	my ($service, $ua, $h) = @_;

	#retrieve the tgt
	my $loginUri = URI->new_abs('v1/tickets', $h->{'casServer'});
	my $tgtResponse = $ua->simple_request(HTTP::Request::Common::POST($loginUri, [
		'username' => $h->{'username'},
		'password' => $h->{'password'},
	]));
	return if($tgtResponse->code != 201);
	my $tgtUri = $tgtResponse->header('Location');

	#retrieve a ticket for the requested service
	my $ticketResponse = $ua->simple_request(HTTP::Request::Common::POST($tgtUri, [
		'service' => $service,
	]));
	return if($ticketResponse->code != 200);
	return $ticketResponse->decoded_content;
};

##Static Methods

#return the default user agent for this class
sub _agent($) {
	return
		$_[0]->SUPER::_agent . ' ' .
		'CAS-UserAgent/' . $VERSION;
}

#Constructor
sub new($%) {
	my $self = shift;
	my (%opt) = @_;

	# remove any cas options before creating base object
	my $cas_opts = delete $opt{'cas_opts'};

	#setup the base object
	$self = $self->SUPER::new(%opt);

	#attach a cas login handler if options were specified
	$self->attach_cas_handler(%$cas_opts) if(ref($cas_opts) eq 'HASH');

	#return this object
	return $self;
}

=head1 METHODS

The following methods are available:

=over 4

=item $ua->attach_cas_handler( %options )

This method attaches a CAS handler to the current C<Authen::CAS::UserAgent>
object.

The following options are supported:

=over

=item C<server> => $url

This option defines the base CAS URL to use for this handler. The base url is
used to detect redirects to CAS for authentication and to issue any requests to
CAS when authenticating.

This option is required.

=item C<username> => $string

This option defines the username to use for authenticating with the CAS server.

This option is required unless using proxy mode.

=item C<password> => $string

This option defines the password to use for authenticating with the CAS server.

This option is required unless using proxy mode.

=item C<restful> => $bool

When this option is TRUE, C<Authen::CAS::UserAgent> will use the RESTful API to
authenticate with the CAS server.

This option defaults to FALSE.

=item C<proxy> => $bool

When this option is TRUE, C<Authen::CAS::UserAgent> using a proxy granting
ticket to authenticate with the CAS server.

This option defaults to FALSE.

=item C<pgt> => $string

This option specifies the proxy granting ticket to use when proxy mode is active.

This option is required when using proxy mode.

=item C<strict> => $bool

When this option is TRUE, C<Authen::CAS::UserAgent> will only allow
authentication for the URL of the request requiring authentication.

This option defaults to FALSE.

=item C<callback> => $cb

This option can be used to specify a custom callback to use when authenticating
with CAS. The callback is called as follows: $cb->($service, $ua, $handler) and
is expected to return a $ticket for the specified service on successful
authentication.

=back

=back

=cut

#method that will attach the cas server login handler
#	server            => the base CAS server uri to add a login handler for
#	username          => the username to use to login to the specified CAS server
#	password          => the password to use to login to the specified CAS server
#	pgt               => the pgt for a proxy login handler
#	proxy             => a boolean indicating this handler is a proxy login handler
#	restful           => a boolean indicating if the CAS server supports the RESTful API
#	callback          => a login callback to use for logging into CAS, it should return a ticket for the specified service
#	ticket_heuristics => an array of heuristic callbacks that are performed when searching for the service and ticket in a CAS response
#	strict            => only allow CAS login when the service is the same as the original url
sub attach_cas_handler($%) {
	my $self = shift;
	my (%opt) = @_;

	#short-circuit if required options aren't specified
	return if(!exists $opt{'server'});
	return if(!$opt{'proxy'} && !(exists $opt{'username'} && exists $opt{'password'}));
	return if($opt{'proxy'} && !$opt{'pgt'});

	#sanitize options
	$opt{'server'} = URI->new($opt{'server'} . ($opt{'server'} =~ /\/$/o ? '' : '/'))->canonical;
	my $callback =
		ref($opt{'callback'}) eq 'CODE' ? $opt{'callback'}    :
		$opt{'proxy'}                   ? $proxyLoginCallback :
		$opt{'restful'}                 ? $restLoginCallback  :
		$defaultLoginCallback;

	# process any default config values for bundled callbacks/heuristics, we do this here
	# instead of in the callbacks to make default values available to custom
	# callbacks
	$opt{'ticket_heuristics'} = [$opt{'ticket_heuristics'}] if(ref($opt{'ticket_heuristics'}) ne 'ARRAY');
	push @{$opt{'ticket_heuristics'}}, $defaultTicketHeuristic;
	@{$opt{'ticket_heuristics'}} = grep {ref($_) eq 'CODE'} @{$opt{'ticket_heuristics'}};

	$opt{'param_heuristics'} = [$opt{'param_heuristics'}] if(ref($opt{'param_heuristics'}) ne 'ARRAY');
	push @{$opt{'param_heuristics'}}, $defaultLoginParamsHeuristic;
	@{$opt{'param_heuristics'}} = grep {ref($_) eq 'CODE'} @{$opt{'param_heuristics'}};

	#remove any pre-existing login handler for the current CAS server
	$self->remove_cas_handlers($opt{'server'});

	#attach a new CAS login handler
	$self->set_my_handler('response_done', $casLoginHandler,
		'owner' => CASHANDLERNAME,
		'casServer' => $opt{'server'},
		'strict'    => $opt{'strict'},
		'loginCb'   => $callback,
		'username'  => $opt{'username'},
		'password'  => $opt{'password'},
		'pgt'       => $opt{'pgt'},
		'config'    => \%opt,
		'errors'    => [],
		'running'   => 0,
		'm_code' => [
			HTTP::Status::HTTP_MOVED_PERMANENTLY,
			HTTP::Status::HTTP_FOUND,
			HTTP::Status::HTTP_SEE_OTHER,
			HTTP::Status::HTTP_TEMPORARY_REDIRECT,
		],
	);

	return 1;
}

sub get_cas_handlers($;$) {
	my $self = shift;
	my ($server) = @_;

	$server = URI->new($server . ($server =~ /\/$/o ? '' : '/'))->canonical if(defined $server);
	return $self->get_my_handler('response_done',
		'owner' => CASHANDLERNAME,
		(defined $server ? ('casServer' => $server) : ()),
	);
}

# method that will retrieve a ticket for the specified service
sub get_cas_ticket($$;$) {
	my $self = shift;
	my ($service, $server) = @_;

	# resolve which handler to use
	my $h;
	if(ref($server) eq 'HASH' && defined $server->{'casServer'}) {
		$h = $server;
	}
	else {
		my @handlers = $self->get_cas_handlers($server);
		die 'too many CAS servers found, try specifying a specific CAS server' if(@handlers > 1);
		$h = $handlers[0];
	}
	die 'cannot find a CAS server to fetch the ST from' if(!$h);

	# get a ticket from the handler
	$h->{'running'}++;
	my $ticket = eval {$h->{'loginCb'}->($service, LWP::UserAgent->new('cookie_jar' => {}), $h)};
	$h->{'running'}--;

	# return the found ticket
	return $ticket;
}

#method that will remove the cas login handlers for the specified cas servers or all if a specified server is not provided
sub remove_cas_handlers($@) {
	my $self = shift;

	#remove cas login handlers for any specified cas servers
	$self->remove_handler('response_done',
		'owner' => CASHANDLERNAME,
		'casServer' => $_,
	) foreach(map {URI->new($_ . ($_ =~ /\/$/o ? '' : '/'))->canonical} @_);

	#remove all cas login handlers if no servers were specified
	$self->remove_handler('response_done',
		'owner' => CASHANDLERNAME,
	) if(!@_);

	return;
}

1;

__END__

=head1 AUTHOR

Daniel Frett

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 - Campus Crusade for Christ International

This is free software, licensed under:

  The (three-clause) BSD License

=cut
