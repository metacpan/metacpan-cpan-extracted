#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

my $test_dir = tempdir();

write_file(File::Spec->catdir($test_dir, 'auto_test'), <<'AUTO');
SiteTitle: Free Geocoder
Contents: Geocoder based on openaddresses and maxmind
Host: geocode.nigelhorne.com
# Where to find the templates
root_dir: /var/www/geocode.nigelhorne.com/
disc_cache: driver=File, root_dir=/tmp/cache
# memory_cache: driver=File, root_dir=/tmp/cache
memory_cache: driver=Memory, global=1
OPENADDR_HOME: /usr/local/share/openaddr
vwflog: /tmp/vwf.log
AUTO

my $config = Config::Abstraction->new(
	path => [$test_dir],
	config_file => 'auto_test'
);

diag(Data::Dumper->new([$config])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_ok($config->get('disc_cache.driver'), 'eq', 'File', 'XML/Colon files correctly handle commas');
cmp_ok($config->all()->{'disc_cache'}{'driver'}, 'eq', 'File', 'XML/Colon files correctly handle commas');

throws_ok( sub  {
	$config = Config::Abstraction->new(
		path => [$test_dir],
		config_file => 'auto_test',
		schema => {
			'SiteTitle' => { 'type' => 'string' },
			'Contents' => { 'type' => 'string' },
			'root_dir' => { 'type' => 'string' },
			'disc_cache' => { 'type' => 'string' },
			'memory_cache' => { 'type' => 'string' },
			'OPENADDR_HOME' => { 'type' => 'string' },
			'config_path' => { 'type' => 'string' },	# Meta variable that is added
			'vwflog' => { 'type' => 'string' },
		},
	)
}, qr/Unknown parameter 'Host'/, 'Disallowed items caught');

done_testing();
