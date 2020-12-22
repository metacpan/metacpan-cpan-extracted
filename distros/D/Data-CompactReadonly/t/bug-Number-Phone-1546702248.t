use strict;
use warnings;

# Tests for bugs found in https://github.com/DrHyde/perl-modules-Number-Phone/runs/1546702248

use Test::More;
use File::Temp qw(tempfile);

use Data::CompactReadonly;

(undef, my $filename) = tempfile(); # UNLINK => 1);

my $data = {
    a   => { anteater => 1, batplague => 1, cat => 1, doge => 1 },
    a2  => {},
    bee => { wasp => 1, hornet => 1, honeybadger => 1 }
};
Data::CompactReadonly->create($filename, $data);
my $db = Data::CompactReadonly->read($filename, tie => 1);
is_deeply($db, $data, "hash structures match");

$data = [
    [
        qw(fish cakes are delicious ),
        [ qw( no really )]
    ],
    [ qw(and numbers are fun 1 2 3 4 5) ],
];
Data::CompactReadonly->create($filename, $data);
$db = Data::CompactReadonly->read($filename, tie => 1);
is_deeply($db, $data, "array structures match");

done_testing();
