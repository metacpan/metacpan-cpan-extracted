package Apache2::AuthCASpbh::Authn;

use strict;
use warnings;

use APR::URI qw ();
use Apache2::Access qw();
use Apache2::AuthCASpbh qw(cfg_value open_session);
use Apache2::AuthCASpbh::Log qw ();
use Apache2::Const -compile => qw(OK DECLINED SERVER_ERROR
				  HTTP_MOVED_TEMPORARILY FORBIDDEN);
use Apache2::Log qw();
use Apache2::Module qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::ServerRec qw();
use Apache2::URI qw();
use Apache2::Util qw();
use CGI qw ();
use CGI::Cookie qw ();
use LWP::UserAgent qw ();
use XML::Simple qw();

our $VERSION = '0.10';

sub handler {
	my ($r) = shift;
	my $now = time();
	my $_log = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);
	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $debug_level = cfg_value($dir_cfg, 'DebugLevel');
	$_log->l($debug_level, 'handler called for ' . $r->unparsed_uri);

	if (my $r_prev = ($r->prev || $r->main)) {
		if (defined $r_prev->user) {
			$_log->l($debug_level, "copying user $r_prev->user from previous request");
			$r->user($r_prev->user);
			return Apache2::Const::OK;
		}
	}

	if ($r->auth_type ne 'Apache2::AuthCASpbh') {
		$_log->l($debug_level, "$r->auth_type not our auth type, declining");
		return Apache2::Const::DECLINED;
	}
		
	$r->push_handlers(PerlCleanupHandler => \&cleanup);

	my $session_db = cfg_value($dir_cfg, 'SessionDBPath') . '/' .
				   cfg_value($dir_cfg, 'SessionDBName');
	$_log->l($debug_level, "using session db $session_db");

	my $cookie_name = cfg_value($dir_cfg, 'SessionCookieName');
	my %cookies = CGI::Cookie->fetch($r);

	if (exists($cookies{$cookie_name})) {
		$_log->l($debug_level, "found $cookie_name cookie " . $cookies{$cookie_name}->value());

		my $session = open_session($session_db, $cookies{$cookie_name}->value());

		if (ref($session)) {
			if ($session->{expiration} > $now) {
				$_log->l($debug_level, 'valid cookie for ' . $session->{user} .
					 ' expires ' . $session->{expiration});
				$r->user($session->{user});

				if (exists($session->{cas_attributes}) &&
				    keys %{$session->{cas_attributes}} > 0) {
					$_log->l($debug_level, 'session contains attributes');
					$r->pnotes(cas_attributes => $session->{cas_attributes});
				}

				if (exists($session->{cas_pgt})) {
					$_log->l($debug_level, 'session contains pgt ' .
						 $session->{cas_pgt});
					$r->pnotes(cas_pgt => $session->{cas_pgt});
				}

				if (exists($session->{cas_proxy})) {
					$_log->l($debug_level, 'session contains proxy chain ' .
						 join(',', @{$session->{cas_proxy}}));
					$r->pnotes(cas_proxy => $session->{cas_proxy});
				}

				$cookies{$cookie_name}->bake($r);

				$r->pnotes(cas_session => $session->{_session_id});
				untie(%{$session});

				return Apache2::Const::OK;
			}
			else {
				$_log->l($debug_level, 'cookie for ' . $session->{user} .
					 ' expired ' . $session->{expiration});

				eval { tied(%{$session})->delete; };
				if ($@) {
		    			$_log->l('warn', "session delete failed - $@");
				}
			}
		}
		elsif ($session !~ /Object does not exist in the data store/) {
		    	$_log->l('error', "session tie failed - $session");
			return Apache2::Const::SERVER_ERROR;
		}
		else {
			$_log->l($debug_level, "session not found");
		}
	}
	else {
		$_log->l($debug_level, "$cookie_name cookie not found");
	}

	my $q = CGI->new($r, $r->args);
	my $qs_nt = $r->args // '';
	if ($qs_nt) {
		$qs_nt =~ s/(^|&)ticket=[^&]+(&|$)/$1$2/;
		$qs_nt =~ s/(^&|&&|&$)//;
	}

	my $service;
	if (defined(cfg_value($dir_cfg, 'ServiceOverride'))) {
		$service = cfg_value($dir_cfg, 'ServiceOverride');
		$_log->l($debug_level, "overriding service to $service");
	}
	else {
		$service = $r->construct_url() . ($qs_nt ? "?$qs_nt" : '');
		$_log->l($debug_level, "set service to $service");
	};
	$service = Apache2::Util::escape_path($service, $r->pool);

	my $st = $q->param('ticket');
	if ($st) {
		my $ua = LWP::UserAgent->new(timeout => 10, keep_alive => 1);

		my $proxy_allow = cfg_value($dir_cfg, 'ProxyAllow');
		my $proxy_allow_re = cfg_value($dir_cfg, 'ProxyAllowRE');

		my $validate_url = cfg_value($dir_cfg, 'ServerURL') .
				   (defined($proxy_allow) || defined($proxy_allow_re) ?
				   	cfg_value($dir_cfg, 'ProxyValidatePath') :
					cfg_value($dir_cfg, 'ServiceValidatePath')) .
				   "?service=$service&ticket=$st";
		$_log->l($debug_level, "validating via URL $validate_url");

		if (cfg_value($dir_cfg, 'RequestPGT')) {
			my $pgt_callback = cfg_value($dir_cfg, 'PGTCallback');

			if ($pgt_callback !~ m#^https://#) {
				$pgt_callback = 'https://' . $r->server->server_hostname .
						 $pgt_callback;
			}

			$_log->l($debug_level, "using PGT callback $pgt_callback");
			$pgt_callback = Apache2::Util::escape_path($pgt_callback, $r->pool);

			$validate_url .= "&pgtUrl=$pgt_callback";
		}

		my $response;
		$response = $ua->get($validate_url);

		if(!$response->is_success()) {
			$_log->l('error', 'ticket validation call failed - ' .
				 $response->status_line());
			return Apache2::Const::SERVER_ERROR;
		}

		my $cas_data = eval { XML::Simple::XMLin($response->content(),
							 ForceArray => [ 'cas:proxy' ]); };
		if ($@) {
			$_log->l('error', "ticket validation xml parse failed - $@");
			return Apache2::Const::SERVER_ERROR;
		}

		if (exists($cas_data->{'cas:authenticationSuccess'})) {
			my $cas_success = $cas_data->{'cas:authenticationSuccess'};
			my $user = $cas_success->{'cas:user'};
			$_log->l($debug_level, "validated user $user");
			$r->user($user);

			my $cas_proxy;
			if (defined($proxy_allow) || defined($proxy_allow_re)) {
				if (exists($cas_success->{'cas:proxies'}{'cas:proxy'})) {
					$cas_proxy = $cas_success->{'cas:proxies'}{'cas:proxy'};

					if (!_allowed_proxy($_log, $debug_level, $cas_proxy,
							    $proxy_allow, $proxy_allow_re)) {
			    			$_log->l($debug_level, 'proxy chain (' .
								       join(' ', @{$cas_proxy}) .
								       ') not permitted');
						return Apache2::Const::FORBIDDEN;
					}
					$_log->l($debug_level, 'proxied via ' .
							       join(' ', @{$cas_proxy}));

					$r->pnotes(cas_proxy => $cas_proxy);
				}
				elsif (cfg_value($dir_cfg, 'ProxyRequired')) {
			    		$_log->l($debug_level, 'proxy chain not found in response');
					return Apache2::Const::FORBIDDEN;
				}
			}

			my $pgt;
			if (cfg_value($dir_cfg, 'RequestPGT')) {
				if (exists($cas_success->{'cas:proxyGrantingTicket'})) {
					my $pgt_iou = $cas_success->{'cas:proxyGrantingTicket'};
					my $pgt_session = open_session($session_db,
								       cfg_value($dir_cfg, 'SessionStateName'));

					$_log->l($debug_level, 'opening global state session ' .
							       cfg_value($dir_cfg, 'SessionStateName'));

					if (!ref($pgt_session)) {
						if ($pgt_session =~ /Object does not exist in the data store/) {
					    		$_log->l('error', 'global state session must be pre-created');
						}
						else {
					    		$_log->l('error', "session tie failed - $pgt_session");
						}
						return Apache2::Const::SERVER_ERROR;
					}

					if (exists($pgt_session->{pgtmap}{$pgt_iou})) {
						$pgt = $pgt_session->{pgtmap}{$pgt_iou}{pgt};
					    	$_log->l($debug_level, "found pgt $pgt");

						delete($pgt_session->{pgtmap}{$pgt_iou});
						$pgt_session->{update_count}++;
						untie(%{$pgt_session});

						$r->pnotes(cas_pgt => $pgt);
					}
					else {
				    		$_log->l('error', "pgt for $pgt_iou not found in session");
						return Apache2::Const::SERVER_ERROR;
					}
				}
				else {
			    		$_log->l($debug_level, 'no pgtiou found in response');
					return Apache2::Const::SERVER_ERROR;
				}
			}
		
			my $cas_attributes = {};
			if (exists($cas_success->{'cas:attributes'})) {

				foreach (keys %{$cas_success->{'cas:attributes'}}) {
					my $key = $_;
					$key =~ s/^cas://;

					$cas_attributes->{$key} =
						$cas_success->{'cas:attributes'}{$_};
				}

			   	$_log->l($debug_level, 'found attributes (' .
						       join(',', keys(%$cas_attributes)) . ')');
				$r->pnotes(cas_attributes => $cas_attributes);
			}

			my $session = open_session($session_db, '');

			if (!ref($session)) {
				$_log->l('error', "session create failed - $session");
				return Apache2::Const::SERVER_ERROR;
			}

			$r->pnotes(cas_session => $session->{_session_id});
			
			$session->{user} = $user;
			$session->{expiration} = time() + cfg_value($dir_cfg, 'SessionTTL');
			$session->{cas_attributes} = $cas_attributes;
			$session->{cas_pgt} = $pgt if $pgt;
			$session->{cas_proxy} = $cas_proxy if $cas_proxy;
			$_log->l($debug_level, 'created session ' . $session->{_session_id} .
					       ' expiration ' . $session->{expiration});

			my $cookie = new CGI::Cookie(-name => $cookie_name,
						     -value => $session->{_session_id},
						     -secure => cfg_value($dir_cfg,
						     			  'SessionCookieSecure'),
						     -path => defined(cfg_value($dir_cfg,
						     				'SessionCookiePath')) ?
								      cfg_value($dir_cfg,
								      		'SessionCookiePath') : undef);
			$cookie->bake($r);

			untie(%{$session});

			if (cfg_value($dir_cfg, 'RemoveServiceTicket')) {
				$_log->l($debug_level, "removing ticket parameter from request args");

				# if $r->args is passed undef, it whines; but can't pass '' as that
				# sets args to empty string instead of undef 8-/
				no warnings 'uninitialized';
				$r->args($qs_nt ? "$qs_nt" : undef);
			}

			return Apache2::Const::OK;
		}
		else {
			if (exists($cas_data->{'cas:authenticationFailure'})) {
				$cas_data->{'cas:authenticationFailure'}{content} =~ s/^[\s\n]*//;
				$cas_data->{'cas:authenticationFailure'}{content} =~ s/[\s\n]*$//;

				$_log->l('error', 'ticket validation failed - ' .
						  $cas_data->{'cas:authenticationFailure'}{content} .
						  '(' . $cas_data->{'cas:authenticationFailure'}{code} . ')');
			}
			else {
				$_log->l('error', "ticket validation invalid response - " .
						  $response->content());
			}

			return Apache2::Const::SERVER_ERROR;
		}
	}

	$r->headers_out->{Location} = cfg_value($dir_cfg, 'ServerURL') .
				      cfg_value($dir_cfg, 'LoginPath') .
				      "?service=$service";

	$_log->l($debug_level, 'redirecting to ' . $r->headers_out->{Location});

	return Apache2::Const::HTTP_MOVED_TEMPORARILY;
}

sub cleanup {
	my ($r) = shift;
	my $now = time();
	my $_log = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);
	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $debug_level = cfg_value($dir_cfg, 'DebugLevel');

	if (!$r->is_initial_req) {
		$_log->l($debug_level, "not initial request, skipping cleanup");
		return Apache2::Const::OK;
	}

	my $session_db = cfg_value($dir_cfg, 'SessionDBPath') . '/' .
			 cfg_value($dir_cfg, 'SessionDBName');
	$_log->l($debug_level, "cleanup using session db $session_db");

	$_log->l($debug_level, 'opening global state session ' .
			       cfg_value($dir_cfg, 'SessionStateName'));
	my $session_state = open_session($session_db,
					 cfg_value($dir_cfg, 'SessionStateName'));
	if (!ref($session_state)) {
		if ($session_state =~ /Object does not exist in the data store/) {
	    		$_log->l('error', 'global state session must be pre-created');
		}
		else {
	    		$_log->l('error', "session tie failed - $session_state");
		}
		return Apache2::Const::SERVER_ERROR;
	}
	
	if (!exists($session_state->{cleanup_time})) {
		$session_state->{cleanup_time} = $now + cfg_value($dir_cfg, 'SessionCleanupInterval');
		$_log->l($debug_level, "initializing cleanup_time to $session_state->{cleanup_time}");
		untie(%{$session_state});
	}
	elsif ($session_state->{cleanup_time} < $now) {
		$session_state->{cleanup_time} = $now + cfg_value($dir_cfg, 'SessionCleanupInterval');
		$_log->l($debug_level, "setting new cleanup_time to $session_state->{cleanup_time}");

		foreach (keys %{$session_state->{pgtmap}}) {
			if ($session_state->{pgtmap}{$_}{expiration} < $now) {
				$_log->l($debug_level, "deleting pgtiou $_ expiration " .
						       $session_state->{pgtmap}{$_}{expiration});
				delete($session_state->{pgtmap}{$_});
			}
		}
		untie(%{$session_state});

		my $all_sessions = Apache::Session::Browseable::SQLite->get_key_from_all_sessions(
					{ DataSource => "dbi:SQLite:$session_db"},
					  sub { return $_[0]->{expiration} } );

		foreach (keys %{$all_sessions}) {
			next if $_ eq cfg_value($dir_cfg, 'SessionStateName');

	    		$_log->l($debug_level, "cleanup found session $_ ($all_sessions->{$_})");
			if ($all_sessions->{$_} < $now) {
				$_log->l($debug_level, "deleting session $_ expiration " .
						       $all_sessions->{$_});

				my $session = open_session($session_db, $_);
				if (ref($session)) {
					eval { tied(%{$session})->delete; };
					if ($@) {
			    			$_log->l('warn', "session delete failed for $_ - $@");
					}
				}
				else {
			    		$_log->l('warn', "session tie failed for $_ - $session");
				}
			}
		}
	}
}

sub _allowed_proxy {
	my ($_log, $debug_level, $cas_proxy, $proxy_allow, $proxy_allow_re) = @_;

	if (defined($proxy_allow)) {
		foreach my $proxy (@{$proxy_allow}) {
			if (grep($_ eq $proxy, @{$cas_proxy})) {
	    			$_log->l($debug_level, "proxy $proxy allowed");
				return 1;
			}
		}
	}
	if (defined($proxy_allow_re)) {
		foreach my $proxy_re (@{$proxy_allow_re}) {
			foreach (@{$cas_proxy}) {
				if ($_ =~ $proxy_re) {
	    				$_log->l($debug_level, "proxy $_ allowed via $proxy_re");
					return 1;
				}
			}
		}
	}

	return 0;
}

=head1 NAME

AuthCASpbh::Authn - CAS SSO authentication for Apache/mod_perl

=head1 SYNOPSIS

	PerlModule Apache2::AuthCASpbh::Authn
	<Location "/myapp">
		AuthType Apache2::AuthCASpbh
		AuthName "CAS"
		PerlAuthenHandler Apache2::AuthCASpbh::Authn
		Require valid-user
	</Location>

=head1 DESCRIPTION

AuthCASpbh::Authn provides CAS authentication for Apache/mod_perl. It can be
used to protect Apache resources, along with built in Apache authorization for
users/groups as well as CAS attribute based authorization provided by
L<Apache::AuthCASpbh::Authz>. Along with L<Apache::AuthCASpbh::UserAgent>,
authentication can be proxied to additional CAS based services. Its operation
can be managed by the configuration variables described in
L<Apache::AuthCASpbh>.

=head2 mod_perl integration

If the resource being protected is a mod_perl application, the following values
will be available in the request pnotes:

=over

=item cas_attributes

A hash of the attributes supplied by the CAS server, if any.

=item cas_pgt

The proxy granting ticket acquired from the CAS server, if C<RequestPGT> is
enabled.

=item cas_proxy

An array of proxies the authentication originated via if the client ticket
provided was a proxy ticket.

=item cas_session

The session identifier for this request.

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
