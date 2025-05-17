package Crop::Server;
use base qw/ Crop::Object Exporter /;

=begin nd
Class: Crop::Server
	Protocol-independent a server logic.
	
	Server process client request in the infinite loop.
	
	Create the Server exemplar, register handlers, define workqueue in the router, then listen.

	Router example:

	(start code)
	...
	$Server->router(sub {
	my $S = shift;
	my $I = $S->I;
	return ['ADD'] if exists $I->{name};
	'LIST';
	});
	(end code)
=cut

use v5.14;
use warnings;
no warnings 'experimental';

use Encode qw/ decode /;
use XML::LibXSLT;
use XML::LibXML;
use XML::Simple;
use JSON;
use CGI::Cookie;

use FindBin qw/ $RealBin /;

use Crop::Debug;
use Crop::Error qw/ all_right warn /;
use Crop::Server::Constants;
use Crop::Server::Handler;
use Crop::HTTP::Session;
use Crop::DateTime;
use Crop::Client;
use Crop::Rights;

=begin nd
Constant: HOMEPAGE
	Homepage of the web-site is always '/'
=cut
use constant {
	HOMEPAGE => '/',
};

=begin nd
Variable: our @EXPORT
	Export by default:
	
	OK - handler return status
=cut
our @EXPORT = qw/ OK PAGELESS /;

=begin nd
Variable: our %Attributes
	Attributes:

	auth      - if true an autentication is required; since true by default, you should redefine the <authenticate ( )> method
	client    - client ID
	content   - body of the response
	cwd       - current working directory
	data      - persistent data across all the handlers of an client request
	json      - JSON exemplar
	handler   - hash of registered handlers
	headers   - HTTP headers for response
	iflow     - Input flow of data (see <I ( )>)
	oflow     - Output flow of data (see <O ( )>)
	            special item named {ERROR} contains hashref of all the errors ocquired (see <Crop::Error>)
	output_t  - type of output ('XML', 'XSLT', 'JSON', and so on)
	page      - filename of output template in cwd
	redirect  - URL to redirect
	request   - client request object, <Crop::HTTP::Request> exemplar; will be Saved manually, so stable=>1
	rights    - rights granted to the client, exemplar of <Crop::Rights>
	router    - method establishes a chain of handlers calls; the reuslt of method is array of handler names
	sendfile  - exemplar of <Crop::File::Send> allowes to download file <Crop::File> from inner url (for Nginx)
	session   - exemplar of <Crop::HTTP::Session>
	tik       - start time of request as <Crop::DateTime> object; server sets a corresponding tok at done time
	user      - user object
	workqueue - array of handlers names establishes executing order
	xslt      - hash of parsed XSLT templates
	
	The 'stable' attribute means 'do not cleanup after request has done'.
=cut
our %Attributes = (
	auth      => {default => 1, stable => 1},
	client    => {mode => 'read'},
	content   => undef,
	cwd       => {stable => 1},
	data      => undef,
	json      => {stable => 1},
	handler   => {stable => 1},
	headers   => undef,
	iflow     => undef,
	oflow     => {mode => 'read'},
	output_t  => {default => 'XSLT', stable => 1},
	page      => undef,
	redirect  => undef,
	request   => {mode => 'read', stable => 1},
	rights    => {mode => 'read'},
	router    => {mode => 'write', stable => 1},  # the same all the time, altough result changes
	sendfile  => {mode => 'read/write'},
	session   => {mode => 'read', stable => 1},   # temporary hack!!! needed by $S->session->restore_param in a script
	tik       => {mode => 'read'},
	user      => undef,
	workqueue => undef,
	xslt      => {stable => 1},
);

=begin nd
Variable: our $Server
	Singlton.
	
	<Crop> 'uses' this class, so Server object must be available from outer classes by accessing directly
	without use of methods of this class.
	
	Getter is <instance ( )>.
=cut
our $Server;

=begin nd
Variable: my $Interrupted
	Signal to interrupt the Server has received.

Variable: my $AtWork
	Server at work should not be killed.
=cut
my ($Interrupted, $AtWork);

# Try the Server to be terminated correctly as possible
$SIG{TERM} = $SIG{INT} = \&interrupt;

=begin nd
Constructor: new ( )
=cut
sub new {
	my $class = shift;
	
	$Server = $class->SUPER::new(
		cwd    => $RealBin,
		@_,
	);
	
	$Server->{json} = JSON->new->allow_nonref->allow_blessed->convert_blessed if $Server->{output_t} eq 'JSON';
# 	$Server->{json}->pretty->canonical if $Server->{json} and Crop::C->{environmentType} ne 'production';

	$Server;
}

=begin nd
Method: add_handler ($name, $handler)
	Add new request handler for the Server main loop.
	
	Order of calls does not matter.
	
	Parses XSLT template for future use.

	(start code)
	$Server->add_handler(ADD => {
		page => 'mypage',  # mypage.xsl template in use; the 'index.xsl' by default; use the 'PAGELESS' constant unless output exists
		input => {
			allow => [qw/ id name description /],
		},
		call => sub {
			my $S = shift;
			my $I = $S->I;
			my $O = $S->O;

			$O->{result} = 25;

			OK;
		},
	});
	(finish code)
	
Parameters:
	$name    - handler name
	$handler - subref
=cut
sub add_handler {
	my ($self, $name, $handler) = @_;

	return warn "SERVER|CRIT: Redefining of handler $name is prohibited" if exists $self->{handler}{$name};

	my $Handler = Crop::Server::Handler->new($handler, name => $name) or return warn "HANDLER|CRIT: Can't initiate handler $name";

	$self->{handler}{$name} = $Handler;
	my $page = $Handler->page || DEFAULT_TPL;

	unless ($page eq PAGELESS) {
		if ($self->{output_t} eq 'XSLT' or $self->{output_t} eq 'XML') {
			eval {
				$self->{xslt}{$page} = XML::LibXSLT->new->parse_stylesheet_file("$self->{cwd}/$page" . XSLT_SUFFIX);
			};
			warn "SERVER|CRIT: $@$!" if $@;
		}
	}
}

=begin nd
Method: _authenticate ( )
	Perform client autentication.
	
	By default returns false, meanning 'the autentication failed'. The 'AUTH' error will arised.
	
	Subclass must redefine this method if any logic is required.

Returns:
	true  - autentication is successful
	flase - if autentication failed
=cut
sub _authenticate { undef }

=begin nd
Method: _cleanup ( )
	Finalyze the current client request.
	
	Cleans all attributes for security reason, so next request will not see stale values.

	Kill the server if it has been marked as 'interrupted'.
=cut
sub _cleanup {
	my $self = shift;

	# reset request-specific data to defaults
	$self->Erase;

	$self->{session}->Save;
	
	$self->{request}->tok(Crop::DateTime->new->timestamp);
	$self->{request}->Save;

	$Interrupted ? die("SERVER|NOTICE: Server stopped") : undef $AtWork;
}

=begin nd
Method: D ( )
	Getter for the 'data' attribute.

Returns:
	$self->{data}
=cut
sub D { shift->{data} }

=begin nd
Method: fail ($err)
	Stop a request if the current handler fails.
	
	Interrupts the working chain and arise the $error.

	Redirect is produced to referer page unless defined html template.

Parameters:
	$err - error message
=cut
sub fail {
	my ($self, $err) = @_;

	warn $err;

# 	debug 'CROPSERVER_FAIL_PAGE=', $self->{handler}->page;
# 	if ($self->{handler}->page eq 'PAGELESS') {
# 		debug 'CROPSERVER_FAIL_PAGELESS';
# 		$self->redirect('/');
# 		$self->redirect($self->{request}->referer);
# 	}

	FAIL;
}

=begin nd
Method: _flush ( )
	Flush response to the client.
	
	Pure virtual method; should be redefined by subclass.
=cut
sub _flush {
	warn 'SERVER|CRIT: Crop::Server->_flush() must be redefined by subclass';
}

=begin nd
Method: I ( )
	The getter of input flow (see the 'iflow' attribute).

Returns:
	hashref of input data
=cut
sub I { shift->{iflow} }

=begin nd
Method: _init ( )
	Initiate request handler loop.
	
	Each iteration process one certain HTTP request:
	
	- remember a start time
	- setup flag 'at work' to prevent destructive cancelation
	- cleanup error stack
	- init HTTP request object and session object
	- cleanup data flows
	- parse incomming CGI parameters
	- exec autentication procedure
	- define workqueue by runing router
	- setup current output page
	
Returns:
	nothing, but errors will established when process goes wrong
=cut
sub _init {
	my $self = shift;

	# remember start time as soon as posible
	$self->{tik} = Crop::DateTime->new;
	
	# it is not a good idea to kill the Server at work
	$AtWork = 1;

	# init Error module
	Crop::Error->erase;
	
	$self->{rights} = Crop::Rights->new;
	$self->{rights}->add_role('admin');

	# set HTTP session and request
	$self->_init_httprequest;

	my $session;
	if (defined $self->{request}->cookie_in) {
		$session = Crop::HTTP::Session->Get(cookie  => $self->{request}->cookie_in);
		$session  //= Crop::HTTP::Session->Get(cookie2 => $self->{request}->cookie_in);
		
		if ($session) {
			$session->generate_cookie;
			$session->mtime($self->{request}->tik);
		}
	}
	unless ($session) {
		$session = Crop::HTTP::Session->new(
			ctime => $self->{request}->tik,
			mtime => $self->{request}->tik,
		);
		$session->generate_cookie;
		$session->Genkey;
	}
	$self->{session} = $session;
	
	unless ($self->{session}->id_client) {
		my $client = Crop::Client->new->Save;
		
		$self->{session}->id_client($client->id);
	}
	
	$self->{request}->id_session($session->id);
	$self->{request}->cookie_out($session->cookie);

	# parse the input flow before the dispatcher starts their work since it operate on input parameters
	$self->{iflow} = {};
	$self->{oflow} = {};
	
	# init data persistent across all the handlers in request
	$self->{data} = {};

	# parse input params
	$self->_parse_input;
	my $json;
	if (defined $self->{request}->content_t and $self->{request}->content_t eq 'application/json') {
		$json = $self->{iflow}{POSTDATA};
	} elsif (exists $self->{iflow}{json} and keys %{$self->{iflow}} == 1) {
		$json = $self->{iflow}{json};
	}
	$self->_parse_json($json) if $json;

	# Authentication
	if ($self->{auth}) {
		$self->_authenticate or warn 'AUTH: Authentication failed';
	}

	# define handlers order
	$self->{workqueue} = defined $self->{router} ? $self->{router}->($self) : ['DEFAULT'] or warn 'NOHANDLER|CRIT: No any handler match the request';
	$self->{workqueue} = [$self->{workqueue}] unless ref $self->{workqueue};  # make arrayref, so router may return handler name as a plain string

	# page could be redefined by handler
	$self->{page} = DEFAULT_TPL;
}

=begin nd
Function: interrupt ($signal)
	Handler of TERM or INT signals.
	
	Interrupt Server gracefully.

	The Apache web server sends TERM for '$ apachectl graceful' command.

	This function uses global 'my' variables instead of server attributes for cut dependency of Server constructor.
	
Parameters:
	$signal - signal
=cut
sub interrupt {
	my $signal = shift;

	warn "SERVER|NOTICE: The $signal signal received";

	$AtWork ? $Interrupted = 1 : die 'SERVER|NOTICE: Server stoped';
};

=begin nd
Method: _init_httprequest ( )
	Create <Crop::HTTP::Request> object from client data.
	
	Pure virtual method.
=cut
sub _init_httprequest { warn 'Crop::Server::_init_httprequest() must be redefined by a subclass' }

=begin nd
Method: instance ( )
	Get Singlton.

Returns:
	$Server object as an singlton.
=cut
sub instance { $Server }

=begin nd
Method: _is_json_correct ($json)
	Check incomming JSON for correctness.

	Input should consists of hashref where items are scalar either hashref.

	Tree traverse uses a loop+stack.

Returns:
	1     - is correct
	undef - otherwise
=cut
sub _is_json_correct {
	my ($self, $json) = @_;

	# 'left' contains a names of json objects of current node were not processed
	# 'node' is the current item of parsing; if left=undef, node were not processed
	my @stack = {left => undef, node => $json};

	while (my $frame = pop @stack) {
		my $node = $frame->{node};
		next unless ref $node;
		
		if (ref $node eq 'HASH') {
			# remember keys of child nodes at the begining of parsing current node
			$frame->{left} = [keys %$node] unless defined $frame->{left};

			@{$frame->{left}} or next;  # all childs is done
			my $key = pop @{$frame->{left}};

			# frame with remaining nodes goes back to the stack for a later parsing
			push @stack, $frame;

			# no info about this node, so 'left' is undef
			push @stack, {left => undef, node => $node->{$key}};
		} elsif (ref $node eq 'ARRAY') {
# 			debug 'ARRAY_AT_JSON';
		} elsif (ref $node eq 'JSON::PP::Boolean') {
			# $$node = 0 or 1; boolean type
		} else {
			return warn 'INPUT: JSON parsing error';  # json is incorrect
		}
	}

	1;
}

=begin nd
Method: listen ( )
	Main loop serves client requests. Pure virtual.

Returns:
	Infinite loop, do not return.
=cut
sub listen {
	return warn 'SERVER|CRIT: Crop::Server::listen() must be redefined by a subclass';
}

=begin nd
Method: O ( )
	The getter of output flow.

Returns:
	hashref
=cut
sub O { shift->{oflow} }

=begin nd
Method: _output ( )
	Build the output and send it to a client.
=cut
sub _output {
	my $self = shift;

	if (defined $self->{sendfile}) {
		$self->_sendfile;
		return;
	}
	
	Crop::Error::bind $self->{oflow}{ERROR};

	my $cookie = CGI::Cookie->new(
		-name    => 'session',
		-value   => $self->{request}->cookie_out,
# 		-domain  => '.' . $self->Config->{host},
		-expires => '+365d',
	);
	my $cookie_secure = CGI::Cookie->new(
		-name    => 'session',
		-value   => $self->{request}->cookie_out,
		-expires => '+365d',
		-secure  => 1,
		-samsite => 'None',
	);
	my ($content, $content_t);
	given ($self->{output_t}) {
		when ('XSLT') {
			if (defined $self->{redirect}) {
# 			unless (defined $self->{redirect}) {
				$self->_redirect;
			} else {
				$self->{headers} = [
					-type   => 'text/html; charset=utf-8',
					-cookie => [$cookie_secure, $cookie],
				];

				my $xml_source = XMLout($self->{oflow}, SuppressEmpty => 1);
				debug DL_SRV, "xml_source=", $xml_source;
				my $xml_parser = XML::LibXML->new;
				my $xml = $xml_parser->load_xml(string => $xml_source);

				my $page = $self->{page};
				my $xslt = $self->{xslt}{$page};
				my $result = $self->{xslt}{$page}->transform($xml);
				$self->{content} = "<!DOCTYPE html>\n" . $xslt->output_as_bytes($result);
			}
		}
		when ('JSON') {
			$self->{headers} = [
				-type   => 'application/json',
# 				-type   => 'text/html; charset=utf-8',
				-cookie => [$cookie_secure, $cookie],
# 				-cookie => $cookie,
			];

			$self->{content} = $self->{json}->utf8->encode($self->{oflow});
		}
		default: warn 'SERVER|ALERT: Unknown content type';
	}
	
	$self->_flush;
}

=begin nd
Method: _parse_input ( )
	Build an input flow ($self->{iflow}) from incomming parameters.
	
	Parameters can contain a dot separator
	>user.name=john&user.email=gmail&
	so the hash will constructed
	>{user => {name=>john, email=>gmail}}
	in the $self->{iflow}
=cut
sub _parse_input {
	my $self = shift;

	my $param = $self->{request}->param;
	for my $name (keys %$param) {
		# separate name to nested hashes
		my @keys = split '\.', $name;

		# only the last name is a lvalue that suitable for assign to parameter
		my $last = pop @keys;

		# step down for all name's parts
		my $target = $self->{iflow};
		for (@keys) {
			# create a new hash for current name
			exists $target->{$_} and ref $target->{$_} eq 'HASH' or $target->{$_} = {};

			# do next step down
			$target = $target->{$_};
		}
		$target->{$last} = decode 'utf8', $param->{$name};
	}
}

=begin nd
Method: _parse_json ($src)
	Decode incomming JSON.
	
	Save result to iflow.
	
Parameters:
	$src - raw JSON from either GET, POST, packed to special param, or Content-Type marked
	
Returns:
	iflow - if ok
	undef - otherwise
=cut
sub _parse_json {
	my ($self, $src) = @_;
	
	my $json = $self->{json}->decode($src);
	$self->_is_json_correct($json) or return warn 'INPUT: Incorrect JSON';

	$self->{iflow} = $json;
}

=begin nd
Method: redirect ($url)
	Make a client redirect to $url in a script.

	> return $Server->redirect('/');

	Sets redirect attribute to the $url, and returns special constant that means 'make redirect' in the main loop of Server.

Parameters:
	$url - addres to redirect

Returns:
	<Crop::Server::Constants::REDIRECT>
=cut
sub redirect {
	my ($self, $url) = @_;

	$self->{redirect} = $url // HOMEPAGE;

	REDIRECT;
}

=begin nd
Method: _redirect ( )
	Send redirect to a client.

	Pure virtual method must be redefined by subclass.
=cut
sub _redirect {
	warn 'SERVER|ALERT: ' . __PACKAGE__ . '::_redirect() method must be redefined by a subclass';
}

=begin nd
Method: _sendfile ( )
	Send X-Accel-Redirect to a client to allow download.
	
	Pure virtual method must be redefined by a subclass.
=cut
sub _sendfile {
	warn 'SERVER|ALERT: ' . __PACKAGE__ . '::_sendfile() method must be redefined by subclass';
}

=begin nd
Method: _work ( )
	Handle current request.
	
	Altough Gateway Interfaces are different, general logic is the same for every client request.
=cut
sub _work {
	my $self = shift;
	
	$self->_init;
	if (all_right) {
		HANDLER:
		while (my $name = shift @{$self->{workqueue}}) {
# 			debug 'HANDLER_NAME=', $name;
			
			unless (exists $self->{handler}{$name}) {
				warn "SERVER|CRIT: No such Handler: $name";
				last HANDLER;
			}
			my $handler = $self->{handler}{$name};

			# check client input for allowed parameters
			unless ($handler->checkin($self->{iflow})) {
				warn 'INPUT|ERR: Input flow does not satisfy to rules of handler ', $handler->name;
				last HANDLER;
			}
			
			my $rc = $handler->call->($self);
			given ($rc) {
				when (OK) {
# 					debug DL_SRV, "RC of handler $name is ", OK;
					$self->{page} = $handler->page || DEFAULT_TPL;
				}
				when (FAIL) {
# 					debug DL_SRV, "RC of handler $name is ", FAIL;
					if ($handler->page eq PAGELESS) {
						$self->{redirect} = $self->{request}->referer;  # TODO: check the original domain
# 						$self->_redirect;

						$self->{session}->pass_thru;
					} else {
						$self->{page} = $handler->page || DEFAULT_TPL;
					}
					last HANDLER;
				}
				when (REDIRECT) {
# 					debug DL_SRV, "RC of handler $name is ", REDIRECT;
# 					$self->_redirect;
					last HANDLER;
				}
				when (WORKFLOW) {
# 					debug DL_SRV, "RC of handler $name is ", WORKFLOW;
				}
				default {
					warn "SERVER|CRIT: Unknown return code: '$rc' in Handler $name";
					last HANDLER;
				}
			}
		}
	}
	warn "SERVER|CRIT: Error at main loop" unless all_right;

	$self->_output;
	$self->_cleanup;
}

1;
