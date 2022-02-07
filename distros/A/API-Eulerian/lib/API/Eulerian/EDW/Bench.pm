#/usr/bin/env perl
###############################################################################
#
# @file Bench.pm
#
# @brief API::Eulerian::EDW Bench module used to get elapsed time of script stages.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 25/11/2021
#
# @version 1.0
#
###############################################################################
#
# Setup perl package name
#
package API::Eulerian::EDW::Bench;
#
# Enforce compilor rules.
#
use strict; use warnings;
#
# Import API::Eulerian::EDW::Chrono
#
use API::Eulerian::EDW::Chrono;
#
# @brief Allocate and initialize a new API::Eulerian::EDW::Bench instance.
#
# @param $class - API::Eulerian::EDW::Bench class.
#
# @return API::Eulerian::EDW::Bench instance.
#
sub new
{
  return bless( {
    _SUITE => {},
    _LAST => undef,
    _FIRST => undef,
  }, shift );
}
#
# @brief Start chronograph.
#
# @param $self - API::Eulerian::EDW::Bench instance.
#
sub start
{
  shift->last( new API::Eulerian::EDW::Chrono() );
}
#
# @brief Get/Set First Stage.
#
# @param $self - API::Eulerian::EDW::Bench instance.
# @param $first - First stage.
#
# @return First stage.
#
sub first
{
  my ( $self, $first ) = @_;
  $self->{ _FIRST } = $first if defined( $first );
  return $self->{ _FIRST };
}
#
# @brief Get/Set Last stage.
#
# @param $self - API::Eulerian::EDW::Bench instance.
# @param $last - Last stage.
#
# @retun Last stage.
#
sub last
{
  my ( $self, $last ) = @_;
  my $first = $self->first();
  $self->{ _LAST } = $last if defined( $last );
  $self->first( $last ) if ! defined( $first );
  return $self->{ _LAST };
}
#
# @brief Stop watching current Stage save elapsed time.
#
# @param $self - API::Eulerian::EDW::Bench instance.
# @param $name - Stage name.
#
# @return Stage.
#
sub stage
{
  my ( $self, $name ) = @_;
  $self->{ _SUITE }->{ $name } = $self->last()->elapsed();
}
#
# @brief Dump Bench stages suites.
#
# @param $self - API::Eulerian::EDW::Bench instance.
#
sub dump
{
  my ( $self ) = @_;
  my %suite = %{$self->{ _SUITE }};

  foreach my $key ( keys %suite ) {
    printf( "%15s : %s\n", $key, $suite{ $key } );
  }
  printf( "%15s : %s\n", 'total', $self->first()->elapsed() );

}
#
# Endup module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::Bench - API::Eulerian::EDW Bench module.

=head1 DESCRIPTION

This module is used to bench script time execution.

=head1 METHODS

=head2 new()

I<Allocate and initialize a new API::Eulerian::EDW::Bench instance>

=head3 output

=over 4

=item * API::Eulerian::EDW::Bench instance.

=back

=head2 start()

I<Start chronograph on current bench stage>

=head3 input

=over 4

=item * API::Eulerian::EDW::Bench instance.

=back

=head2 first()

I<Get chronograph of the first bench stage.>

=head3 input

=over 4

=item * API::Eulerian::EDW::Bench instance.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Chrono instance.

=back

=head2 last()

I<Get chronograph of the last bench stage.>

=head3 input

=over 4

=item * API::Eulerian::EDW::Bench instance.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Chrono instance.

=back

=head2 stage()

I<End counting elapsed time on current stage>

=head3 input

=over 4

=item * API::Eulerian::EDW::Bench instance.

=item * Stage name.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Chrono instance.

=back

=head2 dump()

I<Dump Bench suite>

=head3 input

=over 4

=item * API::Eulerian::EDW::Bench instance.

=back

=head1 SEE ALSO

L<API::Eulerian::EDW::Chrono>

=head1 AUTHOR

Xavier Thorillon <x.thorillon@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 API::Eulerian::EDW Technologies Ltd L<http://www.eulerian.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=cut

