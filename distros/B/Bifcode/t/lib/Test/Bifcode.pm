package Test::Bifcode;
use bytes;
use strict;
use warnings;

use utf8;
use Bifcode qw/decode_bifcode encode_bifcode force_bifcode diff_bifcode/;
use Carp;
use Exporter::Tidy default => [
    qw($bytes $BYTES
      $utf8 $UTF8
      $data1 $DATA1
      $data2 $DATA2
      enc_ok
      enc_error_ok
      decod_ok
      error_ok)
];
use Test::More 0.88;    # for done_testing

our $utf8 = "\x{100}\x{df}";

#'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length = bytes::length($utf8_bytes);
our $UTF8 = 'U' . $utf8_length . ':' . $utf8_bytes . ',';

our $bytes = pack( 's<', 255 );
my $bytes_length = bytes::length($bytes);
our $BYTES = 'B' . $bytes_length . ':' . $bytes . ',';

our $data1 = {
    bools   => [ $Bifcode::FALSE, $Bifcode::TRUE, ],
    bytes   => \$bytes,
    integer => 25,
    float   => -1.25e-9,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA1 = '{'
  . ( 'U5:bools,' . '[01]' )
  . ( 'U5:bytes,' . $BYTES )
  . ( 'U5:float,' . 'F-1.25e-9,' )
  . ( 'U7:integer,' . 'I25,' )
  . ( 'U5:undef,' . '~' )
  . ( 'U4:utf8,' . $UTF8 ) . '}';

our $data2 = {
    bools   => [ $Bifcode::FALSE, $Bifcode::TRUE, ],
    bytes   => \$bytes,
    integer => 24,
    float   => 1.25e-9,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA2 = '{'
  . ( 'U5:bools,' . '[01]' )
  . ( 'U5:bytes,' . $BYTES )
  . ( 'U5:float,' . 'F1.25e-9,' )
  . ( 'U7:integer,' . 'I24,' )
  . ( 'U5:undef,' . '~' )
  . ( 'U4:utf8,' . $UTF8 ) . '}';

sub enc_ok {
    croak 'usage: enc_ok($1,$2)'
      unless 2 == @_;
    my ( $thawed, $frozen ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $diff = diff_bifcode( encode_bifcode($thawed), $frozen );
    length($diff)
      ? ok 0, "encode $frozen:\n$diff"
      : ok 1, "encode $frozen";
}

sub enc_error_ok {
    my ( $data, $error, $kind_of_brokenness ) = @_;
    local $@;
    eval { encode_bifcode $data };
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $have = ref $@;
    my $want = 'Bifcode::Error::' . $error;
    my $ok   = $have eq $want;
    ok $ok, "reject $kind_of_brokenness";
    diag "    wanted:  $want\n    got:     $have" unless $ok;
}

sub un {
    my ($frozen) = @_;
    local $, = ', ';
    my $frozen_str = $frozen // '*undef*';
    return 'ARRAY' eq ref $frozen
      ? ( "decode [@$frozen_str]", decode_bifcode @$frozen )
      : ( "decode '$frozen_str'", decode_bifcode $frozen );
}

sub decod_ok {
    my ( $frozen,   $thawed ) = @_;
    my ( $testname, $result ) = un $frozen;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply $result, $thawed, $testname;
}

sub error_ok {
    my ( $frozen, $error, $kind_of_brokenness ) = @_;
    local $@;
    eval { un $frozen };
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $have = ref $@;
    my $want = 'Bifcode::Error::' . $error;
    my $ok   = $have eq $want;
    ok $ok, "reject $kind_of_brokenness";
    diag "    wanted:  $want\n    got:     $have" unless $ok;
}

1;
