package Apache2::AuthCASpbh::Authz;

use strict;
use warnings;

use Apache2::AuthCASpbh qw(cfg_value open_session);
use Apache2::AuthCASpbh::Log qw();
use Apache2::Const -compile => qw(OK AUTHZ_DENIED_NO_USER
				  AUTHZ_GENERAL_ERROR AUTHZ_NEUTRAL AUTHZ_GRANTED);
use Apache2::Log qw();

our $VERSION = '0.30';

sub authz_attribute {
	my ($auth_type, $r, $requires) = @_;
	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $_log = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);
	my $debug_level = cfg_value($dir_cfg, 'DebugLevel');

	$_log->l($debug_level, 'attribute handler called for ' . $r->unparsed_uri .
			       " with $auth_type require $requires");

	if (!$r->is_initial_req) {
		$_log->l($debug_level, 'not initial request');
		return Apache2::Const::OK;
	}

	if (!defined($r->user)) {
		$_log->l($debug_level, 'no user available');
		return Apache2::Const::AUTHZ_DENIED_NO_USER;
	}
	
	my @requires = split(/\s+/, $requires);
	if (@requires < 1) {
		$_log->l('error', 'no atttribute provided for cas-attribute');
		return Apache2::Const::AUTHZ_GENERAL_ERROR;
	}

	my $cas_attributes = $r->pnotes('cas_attributes');

	if (!defined($cas_attributes)) {
		$_log->l($debug_level, 'no cas attributes found');
		return Apache2::Const::AUTHZ_NEUTRAL;
	}

	my $attribute = shift(@requires);
	if (exists($cas_attributes->{$attribute})) {
		my $cas_attribute = $cas_attributes->{$attribute};
		
		if (@requires == 0) {
			$_log->l($debug_level, "cas attribute $attribute found");
			return Apache2::Const::AUTHZ_GRANTED;
		}
		else {
			$_log->l($debug_level, "cas attribute $attribute value" . (ref($cas_attribute) ?
				   "s " . join(", ", @{$cas_attribute}) : " $cas_attribute"));

			foreach my $lookfor (@requires) {
				if ((!ref($cas_attribute) && $cas_attribute eq $lookfor) ||
				    (ref($cas_attribute) && grep($_ eq $lookfor, @{$cas_attribute}))) {
				     	$_log->l($debug_level, "found $attribute value $lookfor");
					return Apache2::Const::AUTHZ_GRANTED;
				}
			}
		}
		$_log->l($debug_level, "no matching $attribute found in " . (ref($cas_attribute) ?
				       join(' ', @{$cas_attribute}) : $cas_attribute));
	}
	else {
		$_log->l($debug_level, "cas attribute $attribute not found");
	}

	return Apache2::Const::AUTHZ_NEUTRAL;
}

sub authz_attribute_re {
	my ($auth_type, $r, $requires) = @_;
	my $dir_cfg = Apache2::Module::get_config('Apache2::AuthCASpbh',
						  $r->server, $r->per_dir_config);
	my $_log = new Apache2::AuthCASpbh::Log(__PACKAGE__, $r->log);
	my $debug_level = cfg_value($dir_cfg, 'DebugLevel');

	$_log->l($debug_level, 'attribute handler called for ' . $r->unparsed_uri .
			       " with $auth_type require $requires");

	if (!$r->is_initial_req) {
		$_log->l($debug_level, 'not initial request');
		return Apache2::Const::OK;
	}

	if (!defined($r->user)) {
		$_log->l($debug_level, 'no user available');
		return Apache2::Const::AUTHZ_DENIED_NO_USER;
	}
	
	my @requires = split(/\s+/, $requires);
	if (@requires < 2) {
		$_log->l('error', 'no atttribute value provided for cas-attribute-re');
		return Apache2::Const::AUTHZ_GENERAL_ERROR;
	}

	my $cas_attributes = $r->pnotes('cas_attributes');

	if (!defined($cas_attributes)) {
		$_log->l($debug_level, 'no cas attributes found');
		return Apache2::Const::AUTHZ_NEUTRAL;
	}

	my $attribute = shift(@requires);
	if (exists($cas_attributes->{$attribute})) {
		my $cas_attribute = $cas_attributes->{$attribute};
		
		$_log->l($debug_level, "cas attribute $attribute value" . (ref($cas_attribute) ?
			   "s " . join(", ", @{$cas_attribute}) : " $cas_attribute"));

		foreach my $lookfor (@requires) {
			if ((!ref($cas_attribute) && $cas_attribute =~ $lookfor) ||
			    (ref($cas_attribute) && grep($_ =~ $lookfor, @{$cas_attribute}))) {
			     	$_log->l($debug_level, "$attribute value matched $lookfor");
				return Apache2::Const::AUTHZ_GRANTED;
			}
		}
		$_log->l($debug_level, "no matching $attribute found in " . (ref($cas_attribute) ?
				       join(' ', @{$cas_attribute}) : $cas_attribute));
	}
	else {
		$_log->l($debug_level, "cas attribute $attribute not found");
	}

	return Apache2::Const::AUTHZ_NEUTRAL;
}

=head1 NAME

AuthCASpbh::Authz - CAS SSO authorization for Apache/mod_perl

=head1 SYNOPSIS

	PerlModule Apache2::AuthCASpbh::Authz
	PerlAddAuthzProvider cas-attribute Apache2::AuthCASpbh::Authz->authz_attribute
	PerlAddAuthzProvider cas-attribute-re Apache2::AuthCASpbh::Authz->authz_attribute_re
	<Location "/myapp">
		Require cas-attribute memberOf uid=foo,ou=group,dc=example,dc=edu
		Require cas-attribute-re memberOf ^uid=[^,]+-admin,ou=group,dc=example,dc=edu$
		Require cas-attribute department IT Engineering Helpdesk
	</Location>

=head1 DESCRIPTION

AuthCASpbh::Authz provides CAS authorization for Apache/mod_perl. It can be
used to control access to Apache resources using the authentication and
attributes provided by L<Apache::AuthCASpbh::Authn>. Its operation can be
managed by the configuration variables described in L<Apache::AuthCASpbh>.

=head2 Supported require directives

=over

=item C<cas-attribute> I<attribute_name> [I<attribute_value>]...

Control access based on specific values for CAS attributes; access is granted
if the attribute listed contains one of the values listed. If no values are
listed, access is granted if the attribute exists.

=item C<cas-attribute-re> I<attribute_name> I<regex>...

Control access based on regular expression matching against the listed CAS
attribute. Access is granted if any values of the attribute match any of the
provided regular expressions.

=back

=head1 AVAILABILITY

AuthCASpbh is available via CPAN as well as on GitHub at

https://github.com/pbhenson/Apache2-AuthCASpbh

=head1 AUTHOR

Copyright (c) 2018-2024, Paul B. Henson <henson@acm.org>

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

L<Apache2::AuthCASpbh::ProxyCB> - Proxy granting ticket callback module

L<Apache2::AuthCASpbh::UserAgent> - Proxy authentication client

=cut

1;
