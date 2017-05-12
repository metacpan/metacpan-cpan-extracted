# -*- mode: perl -*-

use Test::More tests => 15;

BEGIN {
  use_ok('Compress::Bzip2', qw(:utilities :bzip1));
};


my $string = q/
Twas brillig and the slithy toves
did gire and gimble in the wabe
All mimsey were the borogroves
and the Momewrathes outgrabe
    /;

my $compress = memBzip( $string );
my $uncompress = memBunzip( $compress );

ok( substr($compress,5,16) =~ /^BZh/, "compressed starts with bzip magic header" );

ok( $compress ne $string, "string was not inouted" );
ok( length($compress)-10 < length($string), "string compression - ".length($compress).' vs '.length($string) );
ok( $uncompress eq $string, "uncompressed is same as the original" );

my $string10 = $string x 10;
my $compress10 = memBzip( $string10 );
my $uncompress10 = memBunzip( $compress10 );

ok( $compress10 ne $string10, "x10 string was not inouted" );
ok( length($compress10) < length($string10), "x10 string compression - ".length($compress10).' vs '.length($string10) );
ok( $uncompress10 eq $string10, "x10 uncompressed is same as the original" );

$compress = compress( $string );
$uncompress = decompress( $compress );

ok( $compress ne $string, "bzip1 string was not inouted" );
ok( length($compress)-10 < length($string), "bzip1 string compression - ".length($compress).' vs '.length($string) );
ok( $uncompress eq $string, "bzip1 decompress is same as the original" );

do './t/lib.pl';

# allow plain BZh files with memBunzip also
my $INFILE = catfile( qw(bzlib-src sample0.bz2) );
local $/ = undef;
open( IN, "< $INFILE" ) or die "$INFILE: $!";
binmode IN;
my $sample0 = <IN>;
close( IN );

$uncompress = memBunzip( $sample0 );
ok( $uncompress, "sample0 uncompressed w/o header" );
like( $uncompress, qr/^That\'s great, it starts with an earthquake/ );

my $header = pack("C", 0xf0);
$header .= pack "N", $uncompress ? length($uncompress) : 2027;
$uncompress = memBunzip( $header . $sample0 );
ok( $uncompress, "sample0 uncompressed w/ header" );
like( $uncompress, qr/^That\'s great, it starts with an earthquake/ );
