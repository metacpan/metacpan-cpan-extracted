#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader;
use Data::Dumper;
use FindBin qw/$Bin/;
use IO::File;
use Test::More  tests => 5;
use t::lib::functions;


ok -e "$Bin/../etc/omi.yml", "found omi.yml";

my $test_dir = scratch_dir();

my $config_file = t_copy("$Bin/../etc/omi.yml", '/tmp/dado/omi', $test_dir);

my $conf = join '', IO::File->new("<$config_file")->getlines;

ok $conf, "read config file";

Data::Downloader::Config->init(yaml => $conf, update_ok => 1);

my $new_conf = $conf;

$new_conf =~ s=datacasting:filename=datacasting:foo_filename=;

ok($new_conf ne $conf, 'changed the host in the feed_template');

# TODO fake config update, just show changes
#
# TODO use "update" instead of init?

Data::Downloader::Config->update(yaml => $new_conf);

# my $conf_dump = Data::Downloader::Config->dump(format => 'arrayref');

# diag Dumper($conf_dump);

ok(test_cleanup($test_dir), "Test clean up");

ok((unlink $config_file),"remove $config_file");

