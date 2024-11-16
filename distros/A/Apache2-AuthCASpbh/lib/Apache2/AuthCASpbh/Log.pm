package Apache2::AuthCASpbh::Log;

use strict;
use warnings;

sub new {
	my ($class, $package, $log) = @_;

	$package =~ s/^Apache2:://;
	my $self = { package => $package, log => $log };

	return bless($self, $class);
}

sub l {
	my ($self, $level, $message) = @_;

	$self->{log}->$level("$self->{package}: $message");

	return $message;
}

=head1 NAME

AuthCASpbh::Log - internal logging functionality

=head1 DESCRIPTION

This module provides internal AuthCASpbh functionality and should not be used
by clients.

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

L<Apache2::AuthCASpbh::Authn> - Authorization functionality

L<Apache2::AuthCASpbh::Authz> - Authorization functionality

L<Apache2::AuthCASpbh::ProxyCB> - Proxy granting ticket callback module

L<Apache2::AuthCASpbh::UserAgent> - Proxy authentication client

=cut

1;
