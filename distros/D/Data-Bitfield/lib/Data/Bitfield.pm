#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2017 -- leonerd@leonerd.org.uk

package Data::Bitfield;

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw( bitfield boolfield intfield enumfield constfield );

use Carp;

=head1 NAME

C<Data::Bitfield> - manage integers containing multiple bit fields

=head1 DESCRIPTION

This module provides a single primary function, C<bitfield>, which creates
helper functions in the package that calls it, to assist in managing integers
that encode sets of bits, called bitfields. This may be useful when
interacting with a low-level networking protocol, binary file format, hardware
devices, or similar purposes.

=head2 bitfield

 bitfield $name, %fields

Creates two new functions in the calling package whose names are derived from
the string C<$name> passed here. These functions will be symmetric opposites,
which convert between a key/value list of field values, and their packed
integer or binary byte-string representation.

 $packed_value = pack_$name( %field_values )

 %field_values = unpack_$name( $packed_value )

These two functions will work to a set of field names that match those field
definitions given to the C<bitfield> function that declared them.

Each field has a name and a definition. Its definition comes from one of the
following field-declaration functions.

Additional options may be passed by giving a C<HASH> reference as the first
argument, before the structure name.

 bitfield { %options }, $name, %fields

Recognised options are:

=over 4

=item format => "bytes-LE" | "bytes-BE" | "integer"

Defines the format that the C<pack_NAME> function will return and the
C<unpack_NAME> function will expect to receive as input. The two C<bytes-*>
formats describe a packed binary string in either little- or big-endian
direction, and C<integer> describes an integer numerical value.

Note that currently the C<bytes-*> formats are limited to values 32bits wide
or smaller.

Optional; will default to C<integer> if not supplied. This default may change
in a later version - make sure to always specify it for now.

=item unrecognised_ok => BOOL

If true, the C<pack_> function will not complain about unrecognised field
names; they will simply be ignored.

=back

=cut

sub bitfield
{
   my $pkg = caller;
   bitfield_into_caller( $pkg, @_ );
}

my %VALID_FORMATS = map { $_ => 1 } qw( bytes-LE bytes-BE integer );

sub bitfield_into_caller
{
   my $pkg = shift;
   my %options = ( ref $_[0] eq "HASH" ) ? %{ +shift } : ();
   my ( $name, @args ) = @_;

   my $unrecognised_ok = !!$options{unrecognised_ok};
   my $format = $options{format} // "integer";
   $VALID_FORMATS{$format} or
      croak "Invalid 'format' value $format";

   my $used_bits = 0;

   my $constmask = 0;
   my $constval = 0;

   my %fieldmask;
   my %fieldshift;
   my %fieldencoder;
   my %fielddecoder;
   while( @args ) {
      my $name = shift @args;
      if( !defined $name ) {
         my ( $mask, $value ) = @{ shift @args };

         croak "Constfield collides with other defined bits"
            if $used_bits & $mask;

         $constmask |= $mask;
         $constval |= $value;
         $used_bits |= $mask;

         next;
      }

      ( my $mask, $fieldshift{$name}, $fieldencoder{$name}, $fielddecoder{$name} ) =
         @{ shift @args };

      croak "Field $name is defined twice"
         if $fieldmask{$name};
      croak "Field $name collides with other defined fields"
         if $used_bits & $mask;

      $fieldmask{$name} = $mask;
      $used_bits |= $mask;
   }

   my $nbits = 0;
   $nbits += 8 while( 1 << $nbits < $used_bits );

   my $packsub = sub {
      my %args = @_;
      my $ret = $constval;
      foreach ( keys %args ) {
         my $mask = $fieldmask{$_};
         next if !$mask and $unrecognised_ok;
         croak "Unexpected field '$_'" unless $mask;

         my $v = $args{$_};
         $v = $fieldencoder{$_}($v) if $fieldencoder{$_};
         defined $v or croak "Unsupported value for '$_'";

         if( defined( my $shift = $fieldshift{$_} ) ) {
            no warnings 'numeric';
            int $v eq $v and $v >= 0 and $v <= ( $mask >> $shift ) or
               croak "Expected an integer value for '$_'";
            $ret |= ( $v << $shift ) & $mask;
         }
         else {
            $ret |= $mask if $v;
         }
      }
      return $ret;
   };

   my $unpacksub = sub {
      my ( $val ) = @_;
      # TODO: check constmask
      my @ret;
      foreach ( keys %fieldmask ) {
         my $v = $val & $fieldmask{$_};
         if( defined( my $shift = $fieldshift{$_} ) ) {
            $v >>= $shift;
         }
         else {
            $v = !!$v;
         }

         $v = $fielddecoder{$_}($v) if $fielddecoder{$_};
         push @ret, $_ => $v;
      }
      return @ret;
   };

   if( $format ne "integer" ) {
      my $orig_packsub   = $packsub;
      my $orig_unpacksub = $unpacksub;

      my $big_endian = ( $format eq "bytes-BE" );
      my $pointy = $big_endian ? ">" : "<";

      if( $nbits <= 8 ) {
         $packsub   = sub { pack "C", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( unpack "C", $_[0] ) };
      }
      elsif( $nbits <= 16 ) {
         $packsub   = sub { pack "S$pointy", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( unpack "S$pointy", $_[0] ) };
      }
      elsif( $nbits <= 24 ) {
         if( $big_endian ) {
            $packsub = sub {
               substr( pack( "L>", $orig_packsub->( @_ ) ), 1, 3 )
            };
            $unpacksub = sub {
               $orig_unpacksub->( unpack "L>", "\0$_[0]" )
            };
         }
         else {
            $packsub = sub {
               substr( pack( "L<", $orig_packsub->( @_ ) ), 0, 3 )
            };
            $unpacksub = sub {
               $orig_unpacksub->( unpack "L<", "$_[0]\0" )
            };
         }
      }
      elsif( $nbits <= 32 ) {
         $packsub   = sub { pack "L$pointy", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( unpack "L$pointy", $_[0] ) };
      }
      else {
         croak "Cannot currently handle bytewise packing of $nbits wide values";
      }
   }

   my %subs;

   $subs{"pack_$name"}   = $packsub;
   $subs{"unpack_$name"} = $unpacksub;

   no strict 'refs';
   *{"${pkg}::$_"} = $subs{$_} for keys %subs;
}

=head1 FIELD TYPES

=cut

=head2 boolfield

 boolfield( $bitnum )

Declares a single bit-wide field at the given bit index, whose value is a
simple boolean truth.

=cut

sub boolfield
{
   my ( $bitnum ) = @_;
   return [ 1 << $bitnum, undef ];
}

=head2 intfield

 intfield( $bitnum, $width )

Declares a field of C<$width> bits wide, starting at the given bit index,
whose value is an integer. It will be shifted appropriately.

=cut

sub intfield
{
   my ( $bitnum, $width ) = @_;
   my $mask = ( 1 << $width ) - 1;
   return [ $mask << $bitnum, $bitnum ];
}

=head2 enumfield

 enumfield( $bitnum, @values )

Declares a field some number of bits wide, sufficient to store an integer big
enough to act as an index into the list of values, starting at the given bit
index. Its value will be automatically converted to or from one of the values
given, which should act sensibly as strings for comparison purposes. Holes can
be placed in the range of supported values by using C<undef>.

=cut

sub enumfield
{
   my ( $bitnum, @values ) = @_;
   my $nvalues = scalar @values;

   # Need to ceil(log2) it
   my $width = 1;
   $width++ while ( 1 << $width ) < $nvalues;

   my $def = intfield( $bitnum, $width );
   $def->[2] = sub {
      my $v = shift;
      defined $values[$_] and $v eq $values[$_] and return $_
         for 0 .. $#values;
      return undef;
   };
   $def->[3] = sub {
      return $values[shift];
   };

   return $def;
}

=head2 constfield

 constfield( $bitnum, $width, $value )

Declares a field some number of bits wide that stores a constant value. This
value will be packed automatically.

Unlike other field definitions, this field is not named. It returns a
2-element list directly for use in the C<bitfield> list.

=cut

sub constfield
{
   my ( $bitnum, $width, $value ) = @_;

   $value >= 0 and $value < ( 1 << $width ) or
      croak "Invalid value for constfield of width $width";

   my $mask = ( 1 << $width ) - 1;
   return undef, [ $mask << $bitnum, $value << $bitnum ];
}

=head1 TODO

=over 4

=item *

More flexible error-handling - missing/extra values to C<pack_>, extra bits to C<unpack_>.

=item *

Allow truely-custom field handling, including code to support discontiguous fields.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
