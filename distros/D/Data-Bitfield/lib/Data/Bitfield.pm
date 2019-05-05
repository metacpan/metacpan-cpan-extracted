#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2019 -- leonerd@leonerd.org.uk

package Data::Bitfield;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK = qw( bitfield boolfield intfield enumfield constfield );

use Carp;

=head1 NAME

C<Data::Bitfield> - manage data packed into bytes of multiple bit fields

=head1 SYNOPSIS

   use Data::Bitfield qw( bitfield boolfield enumfield );

   # The stat(2) st_mode field on Linux
   bitfield MODE =>
      format      => enumfield(12,
         undef,     "fifo", "char", undef, "dir",    undef, "block", undef,
         "regular", undef,  "link", undef, "socket", undef, undef,   undef ),
      set_uid     => boolfield(11),
      set_gid     => boolfield(10),
      sticky      => boolfield(9),
      user_read   => boolfield(8),
      user_write  => boolfield(7),
      user_exec   => boolfield(6),
      group_read  => boolfield(5),
      group_write => boolfield(4),
      group_exec  => boolfield(3),
      other_read  => boolfield(2),
      other_write => boolfield(1),
      other_exec  => boolfield(0);

   my %modebits = unpack_MODE( stat($path)->mode );

Z<>

   # The flag register of a Z80
   bitfield FLAGS =>
      sign      => boolfield(7),
      zero      => boolfield(6),
      halfcarry => boolfield(4),
      parity    => boolfield(2),
      subtract  => boolfield(1),
      carry     => boolfield(0);

=head1 DESCRIPTION

This module provides a single primary function, C<bitfield>, which creates
helper functions in the package that calls it, to assist in managing data that
is encoded in sets of bits, called bitfields. This may be useful when
interacting with a low-level networking protocol, binary file format, hardware
devices, or similar purposes.

=head2 bitfield

   bitfield $name, %fields

Creates two new functions in the calling package whose names are derived from
the string C<$name> passed here. These functions will be symmetric opposites,
which convert between a key/value list of field values, and their packed
binary byte-string or integer representation.

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

Note that currently the C<integer> format is limited to values 32bits wide or
smaller.

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

   my $used_bits = '';

   my $constmask = '';
   my $constval = '';

   my %fields;

   while( @args ) {
      my $name = shift @args;
      if( !defined $name ) {
         my ( $shift, $width, $value ) = @{ shift @args };
         my $mask = pack "L<", ( ( 1 << $width ) - 1 ) << $shift;

         croak "Constfield collides with other defined bits"
            if ( $used_bits & $mask ) !~ m/^\0*$/;

         $constval |= pack( "L<", $value << $shift );
         $used_bits |= $mask;

         next;
      }

      my ( $shift, $width, $encoder, $decoder ) = @{ shift @args };
      my $offs = int( $shift / 8 ); $shift %= 8;

      my $mask = ( "\x00" x $offs ) . pack "L<", ( ( 1 << $width ) - 1 ) << $shift;

      croak "Field $name is defined twice"
         if $fields{$name};
      croak "Field $name collides with other defined fields"
         if ( $used_bits & $mask ) !~ m/^\0*$/;

      $fields{$name} = [ $mask, $offs, $shift, $encoder, $decoder ];
      $used_bits |= $mask;
   }

   $used_bits =~ s/\0+$//;
   my $datalen = length $used_bits;

   my $packsub = sub {
      my %args = @_;
      my $ret = $constval;
      foreach ( keys %args ) {
         defined( my $f = $fields{$_} ) or
            $unrecognised_ok and next or
            croak "Unexpected field '$_'";

         my ( $mask, $offs, $shift, $encoder ) = @$f;

         my $v = $args{$_};
         $v = $encoder->($v) if $encoder;
         defined $v or croak "Unsupported value for '$_'";

         {
            no warnings 'numeric';
            int $v eq $v or
               croak "Expected an integer value for '$_'";
         }

         my $bits = ( "\x00" x $offs ) . ( pack "L<", $v << $shift );
         $v >= 0 and ( $bits & ~$mask ) =~ m/^\0+$/ or
            croak "Value out of range for '$_'";

         $ret |= $mask & $bits;
      }
      return substr( $ret, 0, $datalen );
   };

   my $unpacksub = sub {
      my ( $val ) = @_;
      # Bitwise extend so there's always enough bits to unpack
      $val .= "\0\0\0";
      # TODO: check constmask
      my @ret;
      foreach ( keys %fields ) {
         my $f = $fields{$_};
         my ( $mask, $offs, $shift, undef, $decoder ) = @$f;

         my $v = unpack( "L<", substr( $val & $mask, $offs, 4 ) ) >> $shift;

         $v = $decoder->($v) if $decoder;
         push @ret, $_ => $v;
      }
      return @ret;
   };

   if( $format eq "bytes-BE" ) {
      my $orig_packsub   = $packsub;
      my $orig_unpacksub = $unpacksub;

      $packsub = sub {
         return scalar reverse $orig_packsub->(@_);
      };
      $unpacksub = sub {
         return $orig_unpacksub->(scalar reverse $_[0]);
      };
   }
   elsif( $format eq "integer" ) {
      my $orig_packsub   = $packsub;
      my $orig_unpacksub = $unpacksub;

      my $nbits = $datalen * 8;

      if( $nbits <= 8 ) {
         $packsub   = sub { unpack "C", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( pack "C", $_[0] ) };
      }
      elsif( $nbits <= 16 ) {
         $packsub   = sub { unpack "S<", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( pack "S<", $_[0] ) };
      }
      elsif( $nbits <= 24 ) {
         $packsub   = sub { unpack( "L<", $orig_packsub->( @_ ) . "\0" ) };
         $unpacksub = sub { $orig_unpacksub->( pack "L<", $_[0] ) };
      }
      elsif( $nbits <= 32 ) {
         $packsub   = sub { unpack "L<", $orig_packsub->( @_ ) };
         $unpacksub = sub { $orig_unpacksub->( pack "L<", $_[0] ) };
      }
      else {
         croak "Cannot currently handle integer packing of $nbits wide values";
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
   return [ $bitnum, 1, sub { 0 + !!shift }, sub { !!shift } ];
}

=head2 intfield

   intfield( $bitnum, $width )

Declares a field of C<$width> bits wide, starting at the given bit index,
whose value is an integer. It will be shifted appropriately.

=cut

sub intfield
{
   my ( $bitnum, $width ) = @_;
   return [ $bitnum, $width ];
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

   return undef, [ $bitnum, $width, $value ];
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
