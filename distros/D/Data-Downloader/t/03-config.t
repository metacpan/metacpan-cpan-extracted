#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader;
use FindBin qw/$Bin/;
use IO::File;
use Test::More  tests => 4;
use t::lib::functions;


ok(-e "$Bin/../etc/omi.yml", "found omi.yml");

my $test_dir = scratch_dir();

my $config_file = t_copy("$Bin/../etc/omi.yml", '/tmp/dado/omi', $test_dir);

my $conf = join '', IO::File->new("<$config_file")->getlines;

ok($conf, "read conf file");

# Since we're making new linktrees :
Data::Downloader::Symlink::Manager->delete_symlinks(all => 1);

# Since we're deleting disks :
$_->purge for @{ Data::Downloader::File::Manager->get_files(all => 1) };

Data::Downloader::Config->init(yaml => $conf, update_ok => 1);

ok(test_cleanup($test_dir), "Test clean up");

ok unlink $config_file, "cleanup";

1;


