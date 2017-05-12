#!perl
use strict;
use warnings;
use Test::More tests => 11;
use File::Slurp;
use_ok('Compress::LZF_PP');

foreach my $filename ( sort <t/hello*.dat> ) {
    my $data = read_file($filename);
    my ($times) = $filename =~ /hello_(\d+)\./;

    my $want         = 'Hello' x $times;
    my $decompressed = decompress($data);
    is( $decompressed, $want, $filename );
}
