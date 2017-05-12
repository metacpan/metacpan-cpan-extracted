#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use File::Compare;
use File::Path;
use FindBin qw/$Bin/;
use Test::More;
use t::lib::functions;

plan $ENV{DADO_TESTS} ? ( tests => 8 ) : (skip_all => "set DADO_TESTS to run command line tests");

my $t_dir = $Bin;
my $test_dir = scratch_dir();
rmtree($test_dir, { keep_root => 1, safe => 1 });

BAIL_OUT "Test harness is not active; use prove or ./Build test"
    unless($ENV{HARNESS_ACTIVE});

set_path();

my $config_file = t_copy("$Bin/../etc/mds_urn.yml",
			 '/tmp/data_downloader_test', $test_dir);
my $dump_file   = t_copy("$Bin/sample_rss/urn.dd.txt", 
			 '/tmp/data_downloader_test', $test_dir);

my $TMP_DIR = "$test_dir/tmp_dir"; 
ok_system("mkdir -p $TMP_DIR");

ok_system("dado --fatal root config init --file $config_file");

ok_system("dado --fatal root feeds refresh --archiveset 10003 --esdt OMTO3"
	  . " --count 10 --startdate 2008-10-10" 
	  . " --from_file $t_dir/sample_rss/urns.xml --download 1 --fake 1");

ok_system("dado files dump --skip_re 'disk|log_entries|atime'" .
	  " > ${TMP_DIR}/dumped.out");

is(compare("${TMP_DIR}/dumped.out", $dump_file), 0, 'dump comparison 2');

# There should be three files and two symlinks.  (the dir below is in mds_urn.yml)
# ok_system("find $test_dir/dd_store -not -type d | wc -l | egrep -q '^3\$'"); 

ok(test_cleanup($test_dir), "Test clean up");

ok unlink $config_file, 'removed config file';
ok unlink $dump_file, 'removed dump file';

1;

