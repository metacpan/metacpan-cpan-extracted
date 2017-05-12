use strict;
use Test::More tests => 8;
BEGIN { use_ok('DVD::Read::Dvd') };
BEGIN { use_ok('DVD::Read::Dvd::File') };

my $testdir = 'tdvd';

{ # start with shadock, cd n°1

ok(my $dvd = DVD::Read::Dvd->new("$testdir/shadok1"), "can open dvd");
ok(my $file = DVD::Read::Dvd::File->new($dvd, 1, 'IFO'), "can open file");
ok($file->readblock(0, 1), "Can read block");
my ($nb, $data) = $file->readblock(0, 1);
ok($data, "Can read block");
is($nb, 1, "can return nb of block read");
is($file->size, 11, "can return file size");
}
