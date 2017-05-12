#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;
use File::RandomGenerator;

use constant DATA_DIR => '/tmp/backup_ez_testdata';

###### NUKE AND PAVE ######

# delete previous backup dir if exists
my $ez = Backup::EZ->new(
    conf         => 't/ezbackup2.conf',
    exclude_file => 'share/ezbackup_exclude.rsync',
    dryrun       => 1
);
die if !$ez;
system( "rm -rf " . $ez->{conf}->{dest_dir} );

# delete previous test data dir if exists
system("rm -rf " . DATA_DIR);

# generate new test data dirs
system("mkdir -p " . DATA_DIR . "/dir1");

my $frg = File::RandomGenerator->new(
    root_dir => DATA_DIR . '/dir1',
    unlink   => 0,
);
$frg->generate;

system("mkdir -p " . DATA_DIR . "/dir2");

$frg->root_dir(DATA_DIR . '/dir2');
$frg->generate;

# TODO: allow get_list_of_backups to not fail if remote dir does not exist
#ok( !$ez->get_list_of_backups() );

###### RUN BACKUPS ######

$ez = Backup::EZ->new(
    conf         => 't/ezbackup2.conf',
    exclude_file => 'share/ezbackup_exclude.rsync',
    dryrun       => 0
);
die if !$ez;

for ( my $i = 0 ; $i < 3 ; $i++ ) {
    ok( $ez->backup );
    sleep 1;    # sleep 1 to make sure we get a new timestamp
}

my @list = $ez->get_list_of_backups();
ok( @list == 3, "expected 3 dirs, got " . scalar(@list) );

my $cmd = sprintf( "touch %s/junk", $ez->get_dest_dir() );
system($cmd);
die if $?;

# run another backup to test "sudo rm ...." works
ok( $ez->backup );

@list = $ez->get_list_of_backups();
ok( @list == 3 );

###### CLEANUP ######

system("rm -rf " . DATA_DIR);

$cmd = sprintf( "rm -rf %s", $ez->get_dest_dir() );
system($cmd);


system("t/nuke.pl");
done_testing();
