#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;
use File::RandomGenerator;
use File::Path qw(make_path remove_tree);
use File::Touch;

require "t/common.pl";

###### NUKE AND PAVE ######

# delete previous backup dir if exists
my $ez = Backup::EZ->new(
    conf         => 't/ezbackup2.conf',
    exclude_file => 'share/ezbackup_exclude.rsync',
    dryrun       => 1
);
die if !$ez;

nuke();
pave();

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

touch(sprintf("%s/junk", $ez->get_dest_dir() ));

# run another backup to test "sudo rm ...." works
ok( $ez->backup );

@list = $ez->get_list_of_backups();
ok( @list == 3 );

###### CLEANUP ######

nuke();
done_testing();
