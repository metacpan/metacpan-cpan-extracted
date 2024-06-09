##############################################################################
#
#  ISO8583 parsing and construction ISO8583 message data stream
#  Copyright (c) 2011-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#  https://github.com/cade-vs/perl-data-iso8583
#
#  GPL
#
##############################################################################
package Data::ISO8583;
use strict;
use Exporter;

use Encode;
#use Data::Dumper;
#use Data::HexDump;
use Data::Tools 1.44;

our $VERSION = '2.43';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                parse_iso8583_fields
                parse_iso8583_bitmap
    
                );


# ISO 8583:1987

# parses fields, only handles bitmaps and fields data, returns parsed fields, possibly nested
sub parse_iso8583_fields
{
  my $data = shift;
  my $dict = shift; # hash ref with fields dictionary
  my $opt  = shift || {}; 

#print HexDump $data;
  
  my %data; # result data, will be returned as reference
  use Tie::IxHash;
  tie %data, 'Tie::IxHash';

  my ( $fmap, $pos ) = parse_iso8583_bitmap( $data, $opt->{ 'BML' }, $opt->{ 'BMO' }, $opt->{ 'BMB' } );

#print Dumper( $fmap, $pos );
  
  for my $f ( @$fmap )
    {
    my $d = $dict->{ $f };
    die "unknown dictionary field [$f]" unless $d;
    
    my ( $n, $t, $tl, $l, $c ) = @$d{ qw( N T E L C  ) }; # type, len, convert
    my $v;
    if( $t == 0 )
      {
      # skip
      next;
      }
    elsif( $t == 1 )
      {
#print "FIX: $f: \@$pos (\@x".int2hex($pos).") len=$l";
      $v = substr( $data, $pos, $l );
      $pos += $l;
      }
    elsif( $t == 2 )
      {
#print "VAR: $f: \@$pos (\@x".int2hex($pos).")";
      $tl ||= 1; # type len for variable data, bytes count
      die "unsupported variable data length [$tl] for field [$f]" unless $tl == 1 or $tl == 2 or $tl == 4;
      my $ld = substr( $data, $pos, $tl );
      $pos += $tl;
      my $ll = unpack [undef,'C','S',undef,'L']->[$tl], $ld;
      die "field $f has invalid length incoming from data [".str_hex($ld)."] expected $ll + $tl <= $l" unless $ll + $tl <= $l;
      #my $ll = bcd2int( $ld );
      $v = substr( $data, $pos, $ll );
#print " len=$tl byte(s)->".str_hex($ld)."->$ll ";
      $pos += $ll;
      }
    else
      {
      die "not supported type [$t] for field [$f]";
      }
      
#print " HEX:V[".str_hex($v)."]";
    $v = bcd2str( $v ) if $c == 1;
    $v = decode( 'posix-bc', $v ) if $c == 2;
    $v = str_hex( $v ) if $c == 9;
#print "->[$v] || $n\n";
    $data{ $f } = $v;
    }
    
  return \%data;  
}


sub parse_iso8583_bitmap
{
  my $data = shift;
  my $len  = shift || 8; # bitmap length in bytes, default is 8
  my $one  = shift;      # if true, no multiple bitmaps expected, bit 1 regular data
  my $base = shift || 2; # base, defaults to 2

  $base = 1 if $one and ! $base; # if single bitmap, and no base specified, set to 1

  my $fpos = $base - 1;
  my @fmap;
  my $skip = 0;
  while(4)
    {
    my $bm = substr( $data, $skip, $len );

#print "BITMAP: ".str_hex($bm)." skip $skip, len $len\n";
#print HexDump $bm;

    return () unless length( $bm ) == $len;
    my @bm = split //, unpack 'B' . ( $len * 8 ), $bm;

#print Dumper( $one, \@bm );

    my $next = shift @bm unless $one;
    push @fmap, map { ++ $fpos; $_ ? $fpos : (); } @bm;
    $skip += $len;

#print Dumper( $one, \@fmap );

    last unless $next;
    }
  
  return ( \@fmap, $skip ); 
}

# ISO 8583:2003

=pod


=head1 NAME

  ISO8583 parsing and construction of message data stream

=head1 SYNOPSIS

  use Data::ISO8583;
  use Data::ISO8583::VISA;
  
  my $msg_hash_ref = parse_iso8583_fields( $byte_data, $VISA_MESSAGE_FIELDS );
  
  my ( $fmap_arr_ref, $skip ) = parse_iso8583_bitmap( $byte_data, $len, $one, $base );

  my $field_62_hr = parse_iso8583_fields( $msg_hash_ref->{ 62 }, $VISA_MESSAGE_FIELD_62 );

  # field 61 has no bitmap, has only 3 fields, so to use the same parser,
  # fake bitmap has to be passed with first 3 bits set and also bitmap size
  # should be set to 1 (byte, BML) and flag raised that there is no chained bitmaps (BMO)
  my $field_61_hr = parse_iso8583_fields( chr( 0b11100000 ) . $msg_hash_ref->{ 61 }, $VISA_MESSAGE_FIELD_61, { BML => 1, BMO => 1 } );
  
  # field 60 is similar to 61 but there are 10 fields so either larger bitmap is needed (2 bytes)
  # or can be chained two 1-byte bitmaps:
  my $field_60_hr = parse_iso8583_fields( chr( 0b11111111 ) . chr( 0b01110000 ) . $msg_hash_ref->{ 60 }, $VISA_MESSAGE_FIELD_60, { BML => 1 } );

  or:

  my $field_60_hr = parse_iso8583_fields( pack( 'C2', 0b11111111, 0b01110000 ) . $msg_hash_ref->{ 60 }, $VISA_MESSAGE_FIELD_60, { BML => 1, BMB => 1 } );

  or with single bitmap of size 2 bytes without chaining:

  my $field_60_hr = parse_iso8583_fields( pack( 'C2', 0b11111111, 0b11000000 ) . $msg_hash_ref->{ 60 }, $VISA_MESSAGE_FIELD_60, { BML => 2, BMO => 1 } );
  
=head1 FUNCTIONS

=head2 parse_iso8583_fields( $byte_data, $msg_dictionary, \%options );

This functions parses the incoming data stream, using the given message 
dictionary and returns hash reference with parsed fields, keyed by field 
number.

%options argument is optional and is used mostly to pass parameters to
parse_iso8583_bitmap() as:

    {
    BML => $bitmap_length,
    BMO => $true_if_single_bitmap_only,
    BMB => $field_base_index_ie_first_field_number,
    }

=head2 parse_iso8583_bitmap( $byte_data, $len, $one )

This is helper function, used by parse_iso8583_fields() byt can be useful
standalone so it is exported. It takes data stream looks for primary and 
extended bitmaps (no limit for chained bitmaps) and returns array with 
found fields' numbers. It also returns how many bytes are read from the
incoming byte data for the bitmaps. The second return value (skip) is used
to skip bitmap data in the source data:

    my ( $fields_arr_ref, $skip ) = parse_iso8583_bitmap( $byte_data );
    my $fields_data = substr( $byte_data, $skip );
    
This function has two optional arguments:

    $len   -- size of the bitmaps in bytes, defaults to 8
    $one   -- if TRUE no chained bitmaps are searched and bit 1 is regular field
    $base  -- start index of the fields numbering
                * defaults to 2 no bitmap chaining
                * defaults to 1 if single bitmap
                * if specified, given number will be used regardless bitmap count
    
    
=head1 TODO

  (more docs)

=head1 DATA::ISO8583 SUB-MODULES

Data::Tools package includes several sub-modules:

  * Data::ISO8583::VISA  -- VISA-specific dictionaries and functions

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-data-iso8583

  git@github.com:cade-vs/perl-data-iso8583.git
  
  git clone git@github.com:cade-vs/perl-data-iso8583.git
  
  or
  
  git clone https://github.com/cade-vs/perl-data-iso8583.git
  
=head1 AUTHOR

  Copyright (c) 2011-2024 Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  

=cut

1;
