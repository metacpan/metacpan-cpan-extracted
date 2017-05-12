#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Convert::Color::HTML;

use strict;
use warnings;
use base qw( Convert::Color::Library );

# Ensure that Color::Library::Dictionary::HTML is loaded
use Color::Library;

__PACKAGE__->register_color_space( 'html' );

our $VERSION = '0.05';

=head1 NAME

C<Convert::Color::HTML> - color conversion using C<Color::Library::Dictionary::HTML>

=head1 SYNOPSIS

Directly:

 use Convert::Color::HTML;

 my $red = Convert::Color::HTML->new( 'red' );

 my $blue = Convert::Color::HTML->new( '#0000FF' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'html:cyan' );

Conversion from RGB:

 my $green = Convert::Color::RGB->( 0, 1.0, 0 )->as_html;
 say "HTML colour name is " . $green->name;

=head1 DESCRIPTION

This subclass of L<Convert::Color::Library> provides a shortcut to performing
library lookups specifically within the C<HTML> dictionary. Additionally it
will parse C<#RRGGBB> color specifications.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::HTML->new( $name )

Returns a new object to represent the named color from the C<HTML> dictionary
or plain RGB triplet.

=cut

sub new
{
   my $class = shift;
   my ( $name ) = @_;

   if( $name =~ m/^#([0-9a-f]{6})$/i ) {
      my $self = $class->Convert::Color::RGB8::new( $1 );
      $self->[3] = uc "#$1";
      return $self;
   }

   return $class->SUPER::new( "html/$name" );
}

=head1 METHODS

=cut

=head2 $name = $color->name

Returns the name of the color instance; either the C<HTML> dictionary name, or
the plain RGB triplet notation, as was passed to the constructor.

=cut

# Don't register this as a palette space, because we can always represent any
# RGB8 colour. Instead, provide the methods directly

my %palette;

sub new_from_rgb8
{
   my $class = shift;
   my ( $rgb8 ) = @_;

   my $hex = $rgb8->hex;

   unless( keys %palette ) {
      %palette = map {
         my $color = $class->new( $_ );
         $color->hex => $color
      }
      # RT100404 - omit the misspelled 'fuscia'
         grep { $_ ne "fuscia" } Color::Library::Dictionary::HTML->color_names;
   }

   return $palette{$hex} || $class->new( "#$hex" );
}

sub new_rgb
{
   my $class = shift;
   return $class->new_from_rgb8( Convert::Color::RGB->new( @_ )->as_rgb8 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
