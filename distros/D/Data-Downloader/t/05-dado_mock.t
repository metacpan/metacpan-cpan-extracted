#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use File::Basename qw/dirname/;
use File::Compare;
use File::Path;
use FindBin qw/$Bin/;
use Test::More;
use t::lib::functions;

plan $ENV{DADO_TESTS} ? ( tests => 17 ) : (skip_all => "set DADO_TESTS to run command line tests");

BAIL_OUT "Test harness is not active; use prove or ./Build test"
    unless($ENV{HARNESS_ACTIVE});

my $t_dir = $Bin;
my $test_dir = scratch_dir();
rmtree($test_dir, { keep_root => 1, safe => 1 });

set_path();

my $config_file = t_copy("$Bin/../etc/omi.yml", '/tmp/dado/omi', $test_dir);

my $TMP_DIR = "$test_dir/tmp_dir";
ok_system("mkdir -p $TMP_DIR");

ok_system("dado --fatal root config init --file $config_file");

ok_not_system("dado repositories dump_stats 2>&1 | grep -q uninitialized");

ok_not_system("dado disk usage --summary 2>&1 | grep -q uninitialized");

ok_system("dado feeds refresh --archiveset 10003 --esdt OMTO3 --count 10"
	  . " --startproductiontime 2008-10-10"
	  . " --from_file $t_dir/sample_rss/omisips.xml");

ok_system("dado files dump > ${TMP_DIR}/dumped.out");

is(compare("${TMP_DIR}/dumped.out", "$t_dir/sample_rss/omisips.dd.txt"), 0,
   'dump comparison');

ok_system("dado files list > ${TMP_DIR}/list.out");

is(compare("${TMP_DIR}/list.out", "$t_dir/sample_rss/omisips.list.txt"), 0,
   'list comparison');

ok_system("dado files --md5 'like: 8f%' dump | egrep -q 'md5: 8f'");

ok_system("dado files --md5 'like: 8f%' download --fake 1");

# There should be one file and four symlinks.  (two archive sets)
ok_system("find $test_dir -name *.he5 | wc -l | egrep -q '^7\$'");

# Try refreshing and changing the metadata
ok_system("dado --fatal root feeds refresh --archiveset 10003 ".
          "--esdt OMTO3 --count 10 --startproductiontime 2008-10-10 ".
          "--from_file $t_dir/sample_rss/omisips_different_metadata.xml");

ok_system("find $test_dir -name '*.he5' | wc -l | egrep -q '^3\$'");

ok_system("find $test_dir/data/default/19993/ -name '*.he5' | egrep -q 19993");

ok(test_cleanup($test_dir), "Test clean up");

ok unlink $config_file, 'test cleanup';

1;

