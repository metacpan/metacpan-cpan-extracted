use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;
use Ceph::Rados;
use Data::Dump qw/dump/;

my @rnd = ('a'..'z',0..9);

my $pool = $ENV{CEPH_POOL} || 'test_' . join '', map { $rnd[rand @rnd] } 0..9;
my $filename = 'test_file';
my $content = 'test';

my $client = $ENV{CEPH_CLIENT} || 'admin';

my $pool_created_p = system "ceph osd pool create $pool 1"
    unless $ENV{CEPH_POOL};
SKIP: {
    skip "Can't create $pool pool", 21 if $pool_created_p;

    my ($cluster, $io, $list);
    ok( $cluster = Ceph::Rados->new($client), "Create cluster handle" );
    ok( $cluster->set_config_file, "Read config file" );
    ok( $cluster->set_config_option(keyring => "/etc/ceph/ceph.client.$client.keyring"),
        "Set config option 'keyring'" );
    ok( $cluster->connect, "Connect to cluster" );
    ok( $io = $cluster->io($pool), "Open rados pool" );
    ok( $io->write($filename, $content), "Write object" );
    ok( $io->mtime($filename), "Get file mod time" );
    my $length;
    ok( $length = $io->size($filename), "Get file size" );
    is( $length, length($content), "Get correct size" );
    $length = length($content); # just to be sure following tests don't fail if above does
    ok( my $stored_data = $io->read($filename, $length), "Read $length bytes from object" );
    is( $stored_data, $content, "Get back content ok" );
    ok( my $stored_data2 = $io->read($filename), "Read unknown bytes from object" );
    is( $stored_data2, $content, "Get back content ok without read size" );
    ok( my ($stat_size, $stat_mtime) = $io->stat($filename), "Stat object" );
    is( $stat_size, $length, "Stat size is same as content length" );
    ok( $list = $io->list, "Opened list context" );
    my $match = 0;
    while (my $entry = $list->next) {
        #diag "Found $entry";
        $match = 1 if $entry eq $filename;
    }
    ok( $match, "List contains written file" );
    ok( $io->remove($filename), "Remove object" );
    lives_ok { undef $list } "Closed list context";
    lives_ok { undef $io } "Closed rados pool";
    lives_ok { undef $cluster } "Disconnected from cluster";

    system "ceph osd pool delete $pool $pool --yes-i-really-really-mean-it"
        unless $ENV{CEPH_POOL};
}
