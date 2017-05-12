#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Backup::EZ;
use Data::Dumper;


use constant DATA_DIR => '/tmp/backup_ez_testdata';

my $data_dir = shift @ARGV;
if (!$data_dir) {
    $data_dir = DATA_DIR;
}

# delete previous backup dir if exists
my $ez = Backup::EZ->new(
    conf         => 't/ezbackup.conf',
    exclude_file => 'share/ezbackup_exclude.rsync',
    dryrun       => 1
);
die if !$ez;
system( "rm -rf " . $ez->{conf}->{dest_dir} );

# delete previous test data dir if exists
system("rm -rf $data_dir");
