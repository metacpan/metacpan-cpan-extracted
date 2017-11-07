# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::authenticator::passwd;
use strict;
use warnings;
use base qw(ClearPress::authenticator);
use Carp;

our $VERSION = q[477.1.4];

sub authen_credentials {
  my ($self, $ref) = @_;

  if(!$ref ||
     !$ref->{username} ||
     !$ref->{password} ) {
    return;
  }

  my ($name, $passwd) = getpwnam $ref->{username};
  if(!$name) {
    return;
  }

  if((crypt $ref->{password}, $passwd) eq $passwd) {
    return $ref;
  }

  return;
}

1;
__END__

=head1 NAME

ClearPress::authenticator::passwd

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 authen_credentials - attempt to authenticate against passwd/NIS using given username & password

  my $hrAuthenticated = $oPasswd->authen_credentials({username => $sUsername, password => $sPassword});

  returns undef or hashref

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::authenticator

=item Readonly

=item Carp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
