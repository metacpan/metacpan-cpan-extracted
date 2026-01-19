# t/04-hash-flat.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Hash qw(readhash writehash);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $flat_file = "$Bin/data/hash_flat.txt";

my %data = (
    host     => 'localhost',
    port     => 8080,
    debug    => 'true',
);

writehash($flat_file, \%data, {
    delimiter => '=',
    comment   => 'Flat config',
});

my %read;
my ($rc, $msgs) = readhash($flat_file, \%read, {
    delimiter => '=',
    group     => 0,  # flat
});

is($rc, 3, "Read 3 flat entries");
is_deeply(\%read, \%data, "Flat round-trip successful");

unlink $flat_file;
done_testing;
