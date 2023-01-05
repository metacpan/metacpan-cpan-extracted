package Apache2::AuthCASpbh::ProxyCB;

use strict;
use warnings;

use Apache2::AuthCASpbh qw(cfg_value open_session);
use Apache2::AuthCASpbh::Log qw();
use Apache2::Const -compile => qw(HTTP_INTERNAL_SERVER_ERROR HTTP_OK);
use CGI qw ();

our $VERSION = '0.20';

sub handler {
	my ($r) = shift;
	my $_log = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);
	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $debug_level = cfg_value($dir_cfg, 'DebugLevel');

	$_log->l($debug_level, 'handler called for ' . $r->unparsed_uri);

	my $uri = APR::URI->parse($r->pool, $r->unparsed_uri);
	my $q = CGI->new($r, $uri->query);
	my $pgt_iou = $q->param('pgtIou');
	my $pgt = $q->param('pgtId');

	if ($pgt_iou && $pgt) {
		my $session_db = cfg_value($dir_cfg, 'SessionDBPath') . '/' .
				 cfg_value($dir_cfg, 'SessionDBName');
		$_log->l($debug_level, "using session db $session_db global state session " .
				       cfg_value($dir_cfg, 'SessionStateName'));

		my $pgt_session = open_session($session_db,
					       cfg_value($dir_cfg, 'SessionStateName'));

		if (!ref($pgt_session)) {
			if ($pgt_session =~ /Object does not exist in the data store/) {
		    		$_log->l('error', 'global state session must be pre-created');
			}
			else {
				$_log->l('error', "session tie failed - $pgt_session");
			}
			return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
		}

		$pgt_session->{pgtmap}{$pgt_iou}{pgt} = $pgt;
		$pgt_session->{pgtmap}{$pgt_iou}{expiration} =
			time() + cfg_value($dir_cfg, 'PGTIOU_TTL');
		$_log->l($debug_level, "storing $pgt_iou -> $pgt expiration " .
				       $pgt_session->{pgtmap}{$pgt_iou}{expiration});

		$pgt_session->{update_count}++;
		untie(%{$pgt_session});
		
		return Apache2::Const::HTTP_OK;
	}
	else {
		$_log->l('error', 'missing parameters pgt_iou=' . ($pgt_iou // '') .
				  ' pgt= ' . ($pgt // ''));
		return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
	}
}

=head1 NAME

AuthCASpbh::ProxyCB - CAS proxy granting ticket callback handler for Apache/mod_perl

=head1 SYNOPSIS

	PerlModule Apache2::AuthCASpbh::ProxyCB
	<Location "/cas_pgt">
		SetHandler modperl
		PerlResponseHandler Apache2::AuthCASpbh::ProxyCB
	</Location>

=head1 DESCRIPTION

This module provides a handler for the CAS server proxy granting ticket
callback. It should be mapped to whatever location the C<AuthCAS_PGTCallback>
parameter is defined to.

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

L<Apache2::AuthCASpbh::Authn> - Authentication functionality

L<Apache2::AuthCASpbh::Authz> - Authorization functionality

L<Apache2::AuthCASpbh::UserAgent> - Proxy authentication client

=cut

1;
