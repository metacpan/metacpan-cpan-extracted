# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::NED::Query
#
# Astro::NED::Query is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Astro::NED::Query::Objects;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.30';

use autouse Carp => qw/ croak /;
use base qw/ Astro::NED::Query /;

use Astro::NED::Response::Objects;

sub _query
{
    my ( $self ) = @_;

    $self->Format( 'table' );
    $self->ListLimit( 1 );
    $self->ImageStamp( 'NO' );

    return;
}

sub _parse_query
{
  my $self = shift;

  # got something
  if ( $_[0] =~ /\d+ objects found/i )
  {
    my $res = Astro::NED::Response::Objects->new;
    $res->parseHTML( $_[0] );

    return $res;
  }

  # got nothing!
  elsif( $_[0] =~ /No object found/i )
  {
    my $res = Astro::NED::Response::Objects->new;
    return $res;
  }

  else
  {
    my $pfx = ref($self) . '->query: ';
    my @stuff;

#    push @stuff, "error in query:";
#    my @keyw = $self->form;
#    my ( $key, $value );
#    push @stuff, "$key = $value"
#      while ($key, $value) = splice(@keyw, 0, 2 );

    require HTML::Parser;
    my $p = HTML::Parser->new( text_h =>
			    [ sub { push @stuff,
				      grep { ! /NED\ Home
                                                |Search\ Results
                                                |(^NASA.*BASE$)
                                                |(^$)/x }
				      split( /\n+/, shift ) }, 'dtext' ] );
    $p->unbroken_text(1);
    $p->parse( $_[0] );
    $p->eof;

    croak( $pfx, join( "\n$pfx", @stuff ), "\n" );
  }

  return;
}

1;
__END__

=head1 NAME

Astro::NED::Query::Objects - base class for NED Objects queries

=head1 SYNOPSIS

  use base qw/ Astro::NED::Query::Objects /;

=head1 DESCRIPTION

The is the base class for all "Objects" query classes.  It subclasses
the B<Astro::NED::Query> class, and provides the B<_query> and
B<_parse_query> internal methods.  See the documentation for
B<Astro::NED::Query> for more information on those methods.

The B<Astro::NED::Query::ByName>, 
B<Astro::NED::Query::NearName>, 
B<Astro::NED::Query::NearPosition> classes are the actual classes
which should be used.

It sets the following search parameters:

	Format     => 'table'
	ListLimit  => 1
	ImageStamp => 'NO'

=head2 EXPORT

None by default.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (C) 2003 Smithsonian Astrophysical Observatory.
All rights are of course reserved.

It is released under the GNU General Public License.  You may find a
copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 SEE ALSO


L<Astro::NED::Query>
L<Astro::NED::Query::ByName>,
L<Astro::NED::Query::NearName>,
L<Astro::NED::Query::NearPosition>,
L<perl>.

=cut
