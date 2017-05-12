package Data::Dumper::MessagePack;
our $AUTHORITY = 'cpan:GETTY';
$Data::Dumper::MessagePack::VERSION = '0.002';
# ABSTRACT: Dump MessagePack
use 5.008001;
use strict;
use warnings;
no warnings 'recursion';

use Carp ();
use B ();
use Config;
use boolean;
use Term::ANSIColor qw( color );

# Stolen from
# http://cpansearch.perl.org/src/GFUJI/Data-MessagePack-0.48/lib/Data/MessagePack/PP.pm

use Exporter 'import';
our @EXPORT = qw( ddmp );
our @EXPORT_OK = qw( mp_unpack );

BEGIN {
    my $unpack_int64_slow;
    my $unpack_uint64_slow;

    if(!eval { pack 'Q', 1 }) { # don't have quad types
        # emulates quad types with Math::BigInt.
        # very slow but works well.
        $unpack_int64_slow = sub {
            require Math::BigInt;
            my $high = unpack_uint32( $_[0], $_[1] );
            my $low  = unpack_uint32( $_[0], $_[1] + 4);

            if($high < 0xF0000000) { # positive
                $high = Math::BigInt->new( $high );
                $low  = Math::BigInt->new( $low  );
                return +($high << 32 | $low)->bstr;
            }
            else { # negative
                $high = Math::BigInt->new( ~$high );
                $low  = Math::BigInt->new( ~$low  );
                return +( -($high << 32 | $low + 1) )->bstr;
            }
        };
        $unpack_uint64_slow = sub {
            require Math::BigInt;
            my $high = Math::BigInt->new( unpack_uint32( $_[0], $_[1]) );
            my $low  = Math::BigInt->new( unpack_uint32( $_[0], $_[1] + 4) );
            return +($high << 32 | $low)->bstr;
        };
    }

    *unpack_uint16 = sub { return unpack 'n', substr( $_[0], $_[1], 2 ) };
    *unpack_uint32 = sub { return unpack 'N', substr( $_[0], $_[1], 4 ) };

    # For ARM OABI
    my $bo_is_me = unpack ( 'd', "\x00\x00\xf0\x3f\x00\x00\x00\x00") == 1;
    my $unpack_double_oabi;

    # for pack and unpack compatibility
    if ( $] < 5.010 ) {
        my $bo_is_le = ( $Config{byteorder} =~ /^1234/ );

        if ($bo_is_me) {
            $unpack_double_oabi = sub {
                my @v = unpack( 'V2', substr( $_[0], $_[1], 8 ) );
                return unpack( 'd', pack( 'N2', @v[0,1] ) );
            };
        }

        *unpack_int16  = sub {
            my $v = unpack 'n', substr( $_[0], $_[1], 2 );
            return $v ? $v - 0x10000 : 0;
        };
        *unpack_int32  = sub {
            no warnings; # avoid for warning about Hexadecimal number
            my $v = unpack 'N', substr( $_[0], $_[1], 4 );
            return $v ? $v - 0x100000000 : 0;
        };

        # In reality, since 5.9.2 '>' is introduced. but 'n!' and 'N!'?
        if($bo_is_le) {
            *unpack_float = sub {
                my @v = unpack( 'v2', substr( $_[0], $_[1], 4 ) );
                return unpack( 'f', pack( 'n2', @v[1,0] ) );
            };
            *unpack_double = $unpack_double_oabi || sub {
                my @v = unpack( 'V2', substr( $_[0], $_[1], 8 ) );
                return unpack( 'd', pack( 'N2', @v[1,0] ) );
            };

            *unpack_int64 = $unpack_int64_slow || sub {
                my @v = unpack( 'V*', substr( $_[0], $_[1], 8 ) );
                return unpack( 'q', pack( 'N2', @v[1,0] ) );
            };
            *unpack_uint64 = $unpack_uint64_slow || sub {
                my @v = unpack( 'V*', substr( $_[0], $_[1], 8 ) );
                return unpack( 'Q', pack( 'N2', @v[1,0] ) );
            };
        }
        else { # big endian
            *unpack_float  = sub { return unpack( 'f', substr( $_[0], $_[1], 4 ) ); };
            *unpack_double = $unpack_double_oabi || sub { return unpack( 'd', substr( $_[0], $_[1], 8 ) ); };
            *unpack_int64  = $unpack_int64_slow  || sub { unpack 'q', substr( $_[0], $_[1], 8 ); };
            *unpack_uint64 = $unpack_uint64_slow || sub { unpack 'Q', substr( $_[0], $_[1], 8 ); };
        }
    }
    else { # 5.10.0 or later
        if ($bo_is_me) {
            $unpack_double_oabi = sub {
                my $first_word  = substr($_[0], $_[1], 4);
                my $second_word = substr($_[0], $_[1] + 4, 4);
                my $d_bin = $second_word . $first_word;
                return unpack( 'd>', $d_bin );
            };
        }

        *unpack_float  = sub { return unpack( 'f>', substr( $_[0], $_[1], 4 ) ); };
        *unpack_double = $unpack_double_oabi || sub { return unpack( 'd>', substr( $_[0], $_[1], 8 ) ); };
        *unpack_int16  = sub { return unpack( 'n!', substr( $_[0], $_[1], 2 ) ); };
        *unpack_int32  = sub { return unpack( 'N!', substr( $_[0], $_[1], 4 ) ); };

        *unpack_int64  = $unpack_int64_slow  || sub { return unpack( 'q>', substr( $_[0], $_[1], 8 ) ); };
        *unpack_uint64 = $unpack_uint64_slow || sub { return unpack( 'Q>', substr( $_[0], $_[1], 8 ) ); };
    }

    # fixin package symbols
    no warnings 'once';
}

sub _unexpected {
    Carp::confess("Unexpected " . sprintf(shift, @_) . " found");
}

#
# UNPACK
#

our $_utf8 = 1;
my $p; # position variables for speed.

sub _insufficient {
    Carp::confess("Insufficient bytes (pos=$p, type=@_)");
}

sub mp_unpack {
    $p = 0; # init
    my $data = _unpack( $_[0] );
    if($p < length($_[0])) {
        Carp::croak("Data::Dumper::MessagePack->mp_unpack: extra bytes");
    }
    return $data;
}

my $T_RAW             = 0x01;
my $T_ARRAY           = 0x02;
my $T_MAP             = 0x04;
my $T_DIRECT          = 0x08; # direct mapping (e.g. 0xc0 <-> nil)

my @detailed = ( (0x00) x 256 );
my @typemap = ( (0x00) x 256 );

$detailed[$_] = 'fixarray' for
    0x90 .. 0x9f
;
$detailed[0xdc] = 'array16';
$detailed[0xdd] = 'array32';
$detailed[$_] = 'fixmap' for
    0x80 .. 0x8f
;
$detailed[0xde] = 'map16';
$detailed[0xdf] = 'map32';
$detailed[$_] = 'fixstr' for
    0xa0 .. 0xbf
;
$detailed[0xda] = 'str16';
$detailed[0xdb] = 'str32';
$typemap[$_] |= $T_ARRAY for
    0x90 .. 0x9f, # fix array
    0xdc,         # array16
    0xdd,         # array32
;
$typemap[$_] |= $T_MAP for
    0x80 .. 0x8f, # fix map
    0xde,         # map16
    0xdf,         # map32
;
$typemap[$_] |= $T_RAW for
    0xa0 .. 0xbf, # fix raw
    0xda,         # raw16
    0xdb,         # raw32
;

$detailed[0xc3] = 'true';
$detailed[0xc2] = 'false';
$detailed[0xc0] = 'nil';
$detailed[$_] = 'positive fixint' for
    0x00 .. 0x7f
;
$detailed[$_] = 'negative fixint' for
    0xe0 .. 0xff
;
my @byte2value;
foreach my $pair(
    [0xc3, true],
    [0xc2, false],
    [0xc0, undef],

    (map { [ $_, $_ ] }         0x00 .. 0x7f), # positive fixnum
    (map { [ $_, $_ - 0x100 ] } 0xe0 .. 0xff), # negative fixnum
) {
    $typemap[    $pair->[0] ] |= $T_DIRECT;
    $byte2value[ $pair->[0] ]  = $pair->[1];
}

sub _fetch_size {
    my($value_ref, $byte, $x16, $x32, $x_fixbits) = @_;
    if ( $byte == $x16 ) {
        $p += 2;
        $p <= length(${$value_ref}) or _insufficient('x/16');
        return CORE::unpack 'n', substr( ${$value_ref}, $p - 2, 2 );
    }
    elsif ( $byte == $x32 ) {
        $p += 4;
        $p <= length(${$value_ref}) or _insufficient('x/32');
        return CORE::unpack 'N', substr( ${$value_ref}, $p - 4, 4 );
    }
    else { # fix raw
        return $byte & ~$x_fixbits;
    }
}

sub _unpack {
    my ( $value ) = @_;
    $p < length($value) or _insufficient('header byte');
    # get a header byte
    my $byte = ord( substr $value, $p, 1 );
    $p++;

    # +/- fixnum, nil, true, false
    return [ $detailed[$byte], $byte2value[$byte] ]
      if $typemap[$byte] & $T_DIRECT;

    if ( $typemap[$byte] & $T_RAW ) {
        my $size = _fetch_size(\$value, $byte, 0xda, 0xdb, 0xa0);
        my $s    = substr( $value, $p, $size );
        length($s) == $size or _insufficient('raw');
        $p      += $size;
        utf8::decode($s) if $_utf8;
        return [ $detailed[$byte], $s ];
    }
    elsif ( $typemap[$byte] & $T_ARRAY ) {
        my $size = _fetch_size(\$value, $byte, 0xdc, 0xdd, 0x90);
        my @array;
        push @array, _unpack( $value ) while --$size >= 0;
        return [ $detailed[$byte], \@array ];
    }
    elsif ( $typemap[$byte] & $T_MAP ) {
        my $size = _fetch_size(\$value, $byte, 0xde, 0xdf, 0x80);
        my @map;
        while(--$size >= 0) {
            no warnings; # for undef key case
            my $key = _unpack( $value );
            my $val = _unpack( $value );
            push @map, $key, $val;
        }
        return [ $detailed[$byte], \@map ];
    }

    elsif ( $byte == 0xcc ) {
        $p++;
        $p <= length($value) or _insufficient('uint8');
        my $number = CORE::unpack( 'C', substr( $value, $p - 1, 1 ) );
        return [ uint8 => $number ];
    }
    elsif ( $byte == 0xcd ) {
        $p += 2;
        $p <= length($value) or _insufficient('uint16');
        return [ uint16 => unpack_uint16( $value, $p - 2 ) ];
    }
    elsif ( $byte == 0xce ) {
        $p += 4;
        $p <= length($value) or _insufficient('uint32');
        return [ uint32 => unpack_uint32( $value, $p - 4 ) ];
    }
    elsif ( $byte == 0xcf ) {
        $p += 8;
        $p <= length($value) or _insufficient('uint64');
        return [ uint64 => unpack_uint64( $value, $p - 8 ) ];
    }
    elsif ( $byte == 0xd3 ) {
        $p += 8;
        $p <= length($value) or _insufficient('int64');
        return [ int64 => unpack_int64( $value, $p - 8 ) ];
    }
    elsif ( $byte == 0xd2 ) {
        $p += 4;
        $p <= length($value) or _insufficient('int32');
        return [ int32 => unpack_int32( $value, $p - 4 ) ];
    }
    elsif ( $byte == 0xd1 ) {
        $p += 2;
        $p <= length($value) or _insufficient('int16');
        return [ int16 => unpack_int16( $value, $p - 2 ) ];
    }
    elsif ( $byte == 0xd0 ) {
        $p++;
        $p <= length($value) or _insufficient('int8');
        my $number = CORE::unpack('c',  substr( $value, $p - 1, 1 ) );
        return [ int8 => $number ];
    }
    elsif ( $byte == 0xcb ) {
        $p += 8;
        $p <= length($value) or _insufficient('double');
        return [ float64 => unpack_double( $value, $p - 8 ) ];
    }
    elsif ( $byte == 0xca ) {
        $p += 4;
        $p <= length($value) or _insufficient('float');
        return [ float32 => unpack_float( $value, $p - 4 ) ];
    }
    else {
        _unexpected("byte 0x%02x", $byte);
    }
}

our %array_types = map { $_, 1 } qw(
  fixarray array16 array32
);

our %map_types = map { $_, 1 } qw(
  fixmap map16 map32
);

our %type_color;

$type_color{$_} = "blue" for (keys %map_types, keys %array_types);
$type_color{$_} = "yellow" for qw(
  fixstr str16 str32
);
$type_color{$_} = "red" for qw(
  uint8 uint16 uint32 uint64
  int8  int16  int32  int64
  float32      float64
),"positive fixint","negative fixint";
$type_color{$_} = "magenta" for qw(
  true false nil
);

our $type_name_color = "green";

sub _ddmp {
  my ( $depth, $data, $no_prespace ) = @_;
  my $type = $data->[0];
  my $value = $data->[1];
  unless ($no_prespace) {
    print " " x ($depth * 2);    
  }
  print color($type_name_color);
  print $type." ";
  print color($type_color{$type});
  if ($array_types{$type}) {
    print "(".(scalar @{$value}).") [\n";
    for (@{$value}) {
      _ddmp($depth + 1, $_);
    }
    print color($type_color{$type});
    print " " x ($depth * 2);
    print "]";
  } elsif ($map_types{$type}) {
    print "(".((scalar @{$value}) / 2).") {\n";
    my @values = @{$value};
    while (@values) {
      my $key = shift @values;
      my $value = shift @values;
      _ddmp($depth + 1, $key);
      print color($type_color{$type});
      print " " x (($depth + 1) * 2);
      print "=> ";
      _ddmp($depth + 1, $value, 1);
    }
    print color($type_color{$type});
    print " " x ($depth * 2);
    print "}";
  } elsif ($type eq 'nil') {
    print "nil";
  } elsif ($type eq 'true') {
    print "true";
  } elsif ($type eq 'false') {
    print "false";
  } else {
    print $value;
  }
  print "\n".color('reset');
}

sub ddmp {
  my ( $bytes ) = @_;
  my $data = mp_unpack($bytes);
  _ddmp(0, $data);
}

1;

__END__

=pod

=head1 NAME

Data::Dumper::MessagePack - Dump MessagePack

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Data::Dumper::MessagePack;

  ddmp($messagepackbytes);

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #vonbienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-data-dumper-messagepack
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-data-dumper-messagepack/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
