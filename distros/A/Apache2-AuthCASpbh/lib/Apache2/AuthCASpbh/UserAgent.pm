package Apache2::AuthCASpbh::UserAgent;

use strict;
use warnings;

our $VERSION = '0.20';

use parent qw(LWP::UserAgent);

use Apache2::AuthCASpbh qw(cfg_value open_session);
use CGI qw ();
use Data::Dumper qw ();
use XML::Simple qw();

sub new {
	my ($class, %conf) = @_;

	exists($conf{apache_r}) or Carp::croak('apache_r argument missing');
	my $r = $conf{apache_r}; delete($conf{apache_r});

	my $cas_cookie_map;
	if (exists($conf{cas_cookie_map})) {
		$cas_cookie_map = $conf{cas_cookie_map}; delete($conf{cas_cookie_map});
	}

	my $self = $class->SUPER::new(%conf);

	$self->{apache_r} = $r;
	$self->{_log} = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);

	if (defined($cas_cookie_map)) {
		$self->{cas_cookie_map} = $cas_cookie_map;
		$self->cookie_jar({}) unless exists($self->{cookie_jar});
	}

	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $cas_login_url = cfg_value($dir_cfg, 'ServerURL') .
			    cfg_value($dir_cfg, 'LoginPath');

	$self->{debug_level} = cfg_value($dir_cfg, 'DebugLevel');
	$self->{cas_login_url} = qr/^$cas_login_url/;
	$self->{cas_cookie_name} = cfg_value($dir_cfg, 'SessionCookieName');
	$self->{cas_proxy_url} = cfg_value($dir_cfg, 'ServerURL') .
				 cfg_value($dir_cfg, 'ProxyPath');
	$self->{cas_session_db} = cfg_value($dir_cfg, 'SessionDBPath') . '/' .
				  cfg_value($dir_cfg, 'SessionDBName');

	return $self;
}

sub redirect_ok {
	my ($self, $new_request, $response) = @_;
	my $_log = $self->{_log} ;
	my $debug_level = $self->{debug_level};

	if ($response->header('Location') =~ $self->{cas_login_url}) {
		$_log->l($debug_level, 'denying ' . $response->header('Location') .
				       ' redirect, matches ' . $self->{cas_login_url});
		return 0;
	}

	return $self->SUPER::redirect_ok($new_request, $response);
}

sub request {
	my ($self, $request, $arg, $size, $previous) = @_;
	my $_log = $self->{_log};
	my $debug_level = $self->{debug_level};
	my $cas_session = $self->{apache_r}->pnotes('cas_session');
	
	$_log->l('warn', 'no session found for request') and goto NO_SET_COOKIE
		unless defined($cas_session);

	goto NO_SET_COOKIE unless exists($self->{cas_cookie_map});

	my $uri = $request->uri;
	goto NO_SET_COOKIE unless $uri =~ m#http(?:s)?://([^/]+)(/.*)#;
	my ($domain, $path) = ($1, $2);

	foreach my $cme (@{$self->{cas_cookie_map}}) {
		if ($uri =~ /$cme->{URL_re}/) {
			my $url_re = $cme->{URL_re};
			$_log->l($debug_level, "$uri matched $url_re");

			my $session = open_session($self->{cas_session_db}, $cas_session);

			if (ref($session)) {
				foreach my $cookie_key (keys %{$session->{cookies}{$url_re}}) {
					$cookie_key =~ m#([^/]+)(/.*)#;
					my ($cookie_domain, $cookie_path) = ($1, $2);

					if ($domain =~ /\Q$cookie_domain\E$/ && $path =~ /^\Q$cookie_path\E/) {
						$_log->l($debug_level, "adding $cookie_key");

						my @cookie = @{$session->{cookies}{$url_re}{$cookie_key}};
						$self->{cookie_jar}->set_cookie(@cookie);
						last;
					}
				}
				untie(%{$session});
			}
			else {
  				$_log->l('warn', "session tie $cas_session failed - $session");
			}

			last;
		}
	}

	NO_SET_COOKIE:

	my $response = $self->SUPER::request($request, $arg, $size, $previous);

	if ($response->code() == 302 && $response->header('Location') =~ $self->{cas_login_url}) {
		$_log->l($debug_level, "request redirected to CAS login URL $self->{cas_login_url}");

		if (!exists($self->{cas_ua})) {
			$self->{cas_ua} = LWP::UserAgent->new(timeout => 10, keep_alive => 1);
		}

		my $qs = $response->header('Location'); $qs =~ s/^[^\?]+\?//;
		my $q = CGI->new($self->{apache_r}, \$qs);

		my $service = $q->param('service');
		return $_log->l('error', 'no service found in CAS login redirect')
			unless defined($service);

		my $pgt = $self->{apache_r}->pnotes("cas_pgt");
		return $_log->l('error', 'no PGT found for request') unless defined($pgt);

		my $proxy_url = $self->{cas_proxy_url} . "?targetService=" . 
				Apache2::Util::escape_path($service, $self->{apache_r}->pool) .
				"&pgt=$pgt";

		$_log->l($debug_level, "requesting PT via $proxy_url");

		my $response = $self->{cas_ua}->get($proxy_url);

		return $_log->l('error', 'PT request failed - ' . $response->status_line())
			unless $response->is_success();

		my $cas_data = eval { XML::Simple::XMLin($response->content()) };

		return $_log->l('error', "PT request xml parse failed - $@") if ($@);

		if (exists($cas_data->{'cas:proxySuccess'})) {
			my $pt = $cas_data->{'cas:proxySuccess'}{'cas:proxyTicket'};

			my $pt_uri = $service . ($service =~ /\?/ ? '&' : '?') . "ticket=$pt";

			$request->uri($pt_uri);

			$_log->l($debug_level, "resending original request with PT - $pt_uri");
			return $self->request($request, $arg, $size, $previous);
		}
		else {
			if (exists($cas_data->{'cas:proxyFailure'})) {
				$cas_data->{'cas:proxyFailure'}{content} =~ s/^[\s\n]*//;
				$cas_data->{'cas:proxyFailure'}{content} =~ s/[\s\n]*$//;

				return $_log->l('error', 'PT request failed - ' .
						$cas_data->{'cas:proxyFailure'}{content} . ' (' .
						$cas_data->{'cas:proxyFailure'}{code} .')');
			}
			else {
				return $_log->l('error', 'PT request invalid response - ' .
			    			$response->content());
			}
		}
	}

	goto NO_STORE_COOKIE unless exists($self->{cas_cookie_map});
	
	my ($url_re, $session_cookie);

	foreach my $cme (@{$self->{cas_cookie_map}}) {
		my $cookie_name = exists($cme->{cookie_name}) ? $cme->{cookie_name}
							      : $self->{cas_cookie_name};
		$url_re = $cme->{URL_re};

		$_log->l($debug_level, "checking $uri against $url_re for cookie $cookie_name");
		if ($uri =~ /$url_re/) {
			$self->{cookie_jar}->scan(sub {
				my @cookie = @_;
				if ($cookie[1] eq $cookie_name &&
				    $cookie[4] =~ /\Q$domain\E$/ &&
				    $path =~ /^\Q$cookie[3]\E/) {
					$_log->l($debug_level, "found $cookie[3] $cookie[1] $cookie[4]");
					$session_cookie = \@cookie;
				}
			});
				
			last;
		}
	}

	$_log->l($debug_level, 'no matching cookies found') and	goto NO_STORE_COOKIE
		unless ref($session_cookie);

	goto NO_SET_COOKIE unless defined($cas_session);

	my $session = open_session($self->{cas_session_db}, $cas_session);
					
	$_log->l('error', "session $cas_session tie failed - $session") and goto NO_SET_COOKIE
		unless ref($session);

	my $cookie_key = "$session_cookie->[4]$session_cookie->[3]";
	if (!exists($session->{cookies}{$url_re}{$cookie_key}) ||
	    $session->{cookies}{$url_re}{$cookie_key}->[2] ne $session_cookie->[2]) {
		$_log->l($debug_level, 'storing session cookie');
		$session->{cookies}{$url_re}{$cookie_key} = $session_cookie;
		$session->{update_count}++;
	}
	else {
		$_log->l($debug_level, 'no session cookie value change');
	}

	untie(%{$session});

	NO_STORE_COOKIE:

	return $response;
}

=head1 NAME

AuthCASpbh::UserAgent - CAS proxy authentication client for Apache/mod_perl

=head1 SYNOPSIS

	use Apache2::AuthCASpbh::UserAgent;

	my $ua = Apache2::AuthCASpbh::UserAgent->new(
			apache_r => $r,
			cas_cookie_map => [ { URL_re => '^https://my\.server/cas' },
                        	            { URL_re => '^https://other\.server/ssoapp',
					      cookie_name => 'CAS_Cookie' } ]);

	my $req = HTTP::Request->new('GET', 'https://my.server/');

=head1 DESCRIPTION

AuthCASpbh::UserAgent is a derivative of L<LWP::UserAgent> that adds
transparent support for proxy CAS authentication. All of the documentation for
L<LWP::UserAgent> applies, and any method or configuration described in that
documentation is supported by an Apache2::AuthCASpbh::UserAgent object.

AuthCASpbh::UserAgent adds two configuration options to the new() method as
defined by LWP::UserAgent:

=over

=item apache_r

The Apache/mod_perl request object for the request in which
AuthCASpbh::UserAgent is being used. This parameter is mandatory.

=item cas_cookie_map

This parameter controls how AuthCASpbh handles automatically managing CAS
session cookies for requests. It takes a reference to an array, with the array
members being references to hashes with the following components:

=over

=item URL_re

A regular expression compared against the request being made to determine
whether or not this entry applies to the request. Comparisons are made are in
order beginning with the first hash reference in the array, and the first match
ends the search.

=item cookie_name

An optional value defining the name of the session cookie used by the remote
application. If no value is supplied, the value of the SessionCookieName
parameter for the calling request is used.

=back

If no C<cas_cookie_map> is supplied, no automated session management will be
performed and your application is responsible for implementing a mechanism such
that all requests made after the initial successful authentication access that
session, or else authentication will be performed on every request.

Note that if no cookie_jar was supplied and this option exists, a default
cookie_jar will be created. If the request matches one of the URL_re entries,
and a cookie with the configured name is returned, AuthCASpbh::UserAgent will
store the cookie and inject it into future requests that match the same URL_re.

=back

=head1 AVAILABILITY

AuthCASpbh is available via CPAN as well as on GitHub at

https://github.com/pbhenson/Apache2-AuthCASpbh

=head1 AUTHOR

Copyright (c) 2018, Paul B. Henson <henson@acm.org>

This file is part of AuthCASpbh.

AuthCASpbh is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

AuthCASpbh is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
AuthCASpbh.  If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<Apache2::AuthCASpbh> - Overview and configuration details

L<Apache2::AuthCASpbh::Authz> - Authorization functionality

L<Apache2::AuthCASpbh::ProxyCB> - Proxy granting ticket callback module

L<Apache2::AuthCASpbh::UserAgent> - Proxy authentication client

=cut

1;
