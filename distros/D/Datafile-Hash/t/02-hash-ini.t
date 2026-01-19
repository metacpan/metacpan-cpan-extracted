# t/05-hash-ini.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Hash qw(readhash writehash);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $ini_file = "$Bin/data/config.ini";

my %config = (
    global   => { debug => 'on' },
    database => {
        host => 'db.example.com',
        port => 5432,
        name => 'appdb',
    },
    cache => {
        type => 'redis',
        ttl  => 3600,
    },
);

writehash($ini_file, \%config, {
    comment => 'Test INI',
    backup  => 0,
});

my %read;
my ($rc) = readhash($ini_file, \%read, {
    group => 2,
});

is($rc, 6, "Read 6 INI entries");
is($read{database}{host}, 'db.example.com', "Nested access works");
ok(exists $read{global}, "Global section preserved");

unlink $ini_file;
done_testing;
