use strict;
use warnings;
package Dancer::Plugin::CORS;
# ABSTRACT: A plugin for using cross origin resource sharing


use Carp qw(croak confess);
use Dancer ':syntax';
use Dancer::Plugin;
use Sub::Name;
use Scalar::Util qw(blessed);
use URI;

use Dancer::Plugin::CORS::Sharing;

use constant DEBUG => 0;

our $VERSION = '0.13'; # VERSION

my $routes = {};

sub _isin($@) {
	my $test = shift;
	scalar grep { $test eq $_ } @_;
}

sub _isuri(_) {
	shift =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|
}

sub _prefl_handle;
sub _add_rule($%);
sub _handle;

my $current_route;

sub _prefl_handle {
	debug "[CORS] entered preflight request main subroutine" if DEBUG;
	unless (defined $current_route) {
		warning "[CORS] current route not defined!";
		return;
	}
	unless(_handle($current_route)) {
		my $request = Dancer::SharedData->request;
		while ($current_route = $current_route->next) {
			if ($current_route->match($request)) {
				debug "[CORS] going to next handler" if DEBUG;
				pass;
			}
        }
		debug "[CORS] no more rules." if DEBUG;
	}
	$current_route = undef;
}

sub _add_rule($%) {
	my ($route, %options) = @_;
	
	if (ref $route eq 'ARRAY') {
	    return map { _add_rule($_, %options) } @$route;
	}

	if (blessed $route and $route->isa('Dancer::Route')) {
		my $prefl = Dancer::App->current->registry->add_route(Dancer::Route->new(
			method => 'options',
			code => \&_prefl_handle,
			options => $route->options,
			pattern => $route->pattern
		));
		$options{method} = uc($route->method);
		$routes->{$prefl} = [{ %options }];
		debug "registered preflight route handler for ".$route->method." pattern: ".$route->pattern."\n" if DEBUG;
	}
	
	unless (exists $routes->{$route}) {
		$routes->{$route} = [];
		unless (ref $route) {
			debug "registered preflight route handler for any pattern: $route\n" if DEBUG;
			options $route => \&_prefl_handle;
		}
	}
	push @{ $routes->{$route} } => \%options;
}

sub _handle {
	my $route = shift;
	my $request = Dancer::SharedData->request;
	my $path = $request->path_info;
	
	unless (exists $routes->{$path} or exists $routes->{$route}) {
		debug "[CORS] path $path or route $route did not no matched any rule" if DEBUG;
	}
	
	my $preflight = uc $request->method eq 'OPTIONS';
	
	debug "[CORS] preflight request" if DEBUG and $preflight;
	
	my $origin = scalar($request->header('Origin'));
	
	unless (defined $origin) {
		debug "[CORS] no origin header present in request" if DEBUG;
		return;
	}

	unless (_isuri($origin)) {
		debug "[CORS] origin '$origin' is not a URI" if DEBUG;
		return;
	}
	
	my $requested_method  = $preflight
	                      ? scalar($request->header('Access-Control-Request-Method'))
						  : $request->method
						  ;
	unless (defined $requested_method) {
		debug "[CORS] no request method defined" if DEBUG;
	}

	my @requested_headers = map { s{\s+}{}g; $_ } split /,+/, (scalar($request->header('Access-Control-Request-Headers')) || '');
	
	my ($ok, $i) = (0, 0);
	my ($headers, $xoptions);
	
	if (exists $routes->{$route}) {
		$path = "$route";
		debug "[CORS] dynamic route: $path" if DEBUG;
	} else {
		debug "[CORS] static route: $path" if DEBUG;
	}
	
	my $n = scalar @{$routes->{$path}};
	
	RULE: foreach my $options (@{$routes->{$path}}) {
		debug "[CORS] testing rule ".++$i." of $n" if DEBUG;
		if (DEBUG) {
			use Data::Dumper;
			debug Dumper($options);
		}
		$headers = {};
		if (exists $options->{origin}) {
			my $reftype = ref $options->{origin};
			if ($reftype eq 'CODE') {
				if (!$options->{origin}->(URI->new($origin))) {
					debug "[CORS] origin $origin did not matched against coderef" if DEBUG;
					next RULE;
				}
			} elsif ($reftype eq 'ARRAY') {
				unless (_isin $origin => @{ $options->{origin} }) {
					debug "[CORS] origin $origin is not in array" if DEBUG;
					next RULE;
				}
			} elsif ($reftype eq 'Regexp') {
				unless ($origin =~ $options->{origin}) {
					debug "[CORS] origin $origin did not matched against regexp" if DEBUG;
					next RULE;
				}
			} elsif ($reftype eq '') {
				unless ($options->{origin} eq $origin) {
					debug "[CORS] origin $origin did not matched against static string" if DEBUG;
					next RULE;
				}
			} else {
				confess("unknown origin type: $reftype");
			}
		} else {
			$origin = '*';
		}
		$headers->{'Access-Control-Allow-Origin'} = $origin;
		$headers->{'Vary'} = 'Origin' if $origin ne '*';
		
		if (exists $options->{timing}) {
			if (defined $options->{timing} and $options->{timing} eq '1') {
				$headers->{'Timing-Allow-Origin'} = $headers->{'Access-Control-Allow-Origin'};
			} else {
				$headers->{'Timing-Allow-Origin'} = 'null';
			}
		}
		
		if (exists $options->{credentials}) {
			if (!!$options->{credentials}) {
				if ($origin eq '*') {
					warning('For a resource that supports credentials a origin matcher must be specified.');
					next RULE;
				}
				$headers->{'Access-Control-Allow-Credentials'} = 'true' ;
			}
		}
		
		if (exists $options->{expose}) {
			$headers->{'Access-Control-Expose-Headers'} = $options->{expose};
		}
		
		if (exists $options->{methods}) {
			unless (_isin lc $requested_method => map lc, @{ $options->{methods} }) {
				debug "[CORS] request method not allowed" if DEBUG;
				next RULE;
			}
			$headers->{'Access-Control-Allow-Methods'} = join ', ' => map uc, @{ $options->{methods} };
		} elsif (exists $options->{method}) {
			unless ($options->{method} eq $requested_method) {
				debug "[CORS] request method '$requested_method' not allowed: ".$options->{method} if DEBUG;
				next RULE;
			}
			$headers->{'Access-Control-Allow-Methods'} = $options->{method};
		}
		
		if (exists $options->{headers}) {
			foreach my $requested_header (@requested_headers) {
				unless (_isin lc $requested_header => map lc, @{ $options->{headers} }) {
					debug "[CORS] requested headers did not match allowed in rule" if DEBUG;
					next RULE;
				}
			}
			$headers->{'Access-Control-Allow-Headers'} = join ', ' => @{ $options->{headers} };
		} elsif (@requested_headers) {
			$headers->{'Access-Control-Allow-Headers'} = join ', ' => @requested_headers;
		}

		if ($preflight and exists $options->{maxage}) {
			$headers->{'Access-Control-Max-Age'} = $options->{maxage};
		}
		
		$ok = 1;
		var CORS => {%$options};
		Dancer::SharedData->response->headers(%$headers);
		if (DEBUG) {
			use Data::Dumper;
			debug Dumper({headers => $headers});
		}
		last RULE;
	}

	if ($ok) {
		debug "[CORS] matched!" if DEBUG;
	} else {
		debug "[CORS] no rule matched" if DEBUG;
	}
	
	return $ok;
}


register(share => \&_add_rule);

hook(before => sub {
	$current_route = shift || return;
	my $preflight = uc Dancer::SharedData->request->method eq 'OPTIONS';
	if ($preflight) {
		debug "[CORS] pre-check: preflight request, handle within main subroutine" if DEBUG;
	} else {
		debug "[CORS] pre-check: no preflight, handle actual request now" if DEBUG;
		_handle($current_route);
	}
});

my $current_sharing;


register sharing => sub {
	my $class = __PACKAGE__.'::Sharing';
	$current_sharing ||= $class->new(@_,_add_rule=>\&_add_rule);
	return $current_sharing;
};

register_plugin;
1;

__END__

=pod

=head1 NAME

Dancer::Plugin::CORS - A plugin for using cross origin resource sharing

=head1 VERSION

version 0.13

=head1 DESCRIPTION

Cross origin resource sharing is a feature used by modern web browser to bypass cross site scripting restrictions. A webservice can provide those rules from which origin a client is allowed to make cross-site requests. This module helps you to setup such rules.

=head1 SYNOPSIS

    use Dancer::Plugin::CORS;

    get '/foo' => sub { ... };
	share '/foo' =>
		origin => 'http://localhost/',
		credentials => 1,
		expose => [qw[ Content-Type ]],
		method => 'GET',
		headers => [qw[ X-Requested-With ]],
		maxage => 7200,
		timing => 1,
	;

=head1 METHODS

=head2 share(C<$route>, C<%options>)

The parameter C<$route> may be any valid path like used I<get>, I<post>, I<put>, I<delete> or I<patch> but not I<option>.

Alternatively a L<Dancer::Route> object may be used instead:

	$route = post '/' => sub { ... };
	share $route => ... ;

Or a arrayref to one or more Routes:

	@head_and_get = get '/' => sub { ... };
	share \@head_and_get => ...;

This syntax works too:

	share [ get ('/' => sub { ... }) ] => ...;

For any route more than one rule may be defined. The order is relevant: the first matching rule wins.

Following keywords recognized by C<%options>:

=over 4

=item I<origin>

This key defines a static origin (scalar), a list (arrayref), a regex or a subroutine.

If not specified, any origin is allowed.

If a subroutine is used, the first passed parameter is a L<URI> object. It should return a true value if this origin is allowed to access the route in question; otherwise false.

	origin => sub {
		my $host = shift->host;
		# allow only from localhost
		grep { $host eq $_ } qw(localhost 127.0.0.1 ::1)
	}

Hint: a origin consists of protocol, hostname and maybe a port. Examples: C<http://www.example.com>, C<https://securesite.com>, C<http://localhost:3000>, C<http://127.0.0.1>, C<http://[::1]>

=item I<credentials>

This indicates whether cookies, HTTP authentication and/or client-side SSL certificates may sent by a client. Allowed values are C<0> or C<1>.

This option must be used together with I<origin>.

=item I<expose>

A comma-seperated list of headers, that a client may extract from response for use in a client application.

=item I<methods>

A arrayref of allowed methods. If no methods are specified, all methods are allowed.

=item I<method>

A string containing a single supported method. This parameter is autofilled when I<share()> is used together with a L<Dancer::Route> object. If no method is specified, any method is allowed.

=item I<headers>

A arrayref of allowed request headers. In most cases that should be C<[ 'X-Requested-With' ]> when ajax requests are made. If no headers are specified, all requested headers are allowed.

=item I<maxage>

A maximum time (in seconds) a client may cache a preflight request. This can decrease the amount of requests made to the webservice.

=item I<timing>

Allow access to the resource timing information. If set to 1, the header C<Timing-Allow-Origin> is set to the same value as I<Access-Control-Allow-Origin>. Otherwise, its set to the value I<null>. If the keyword is not present, no I<Timing-Allow-Origin> header will be appended to response. See L<http://www.w3.org/TR/resource-timing/#cross-origin-resources> for more information.

=back

=head2 sharing

This keyword is a helper for re-using rules for many routes.

See L<Dancer::Plugin::CORS::Sharing> for more information about this feature.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer-plugin-cors-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
