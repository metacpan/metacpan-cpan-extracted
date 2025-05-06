#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use YAML::XS qw/DumpFile/;

use_ok('CGI::Info');

# Create a temp config file
my $tempdir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catdir($tempdir, 'config.yml');

# Write a fake config
my $class_name = 'CGI::Info';

DumpFile($config_file, {
	$class_name => { max_upload_size => 2 }
});

# Create object using the config_file
my $obj = CGI::Info->new(config_file => $config_file);

ok($obj, 'Object was created successfully');
isa_ok($obj, 'CGI::Info');
cmp_ok($obj->{'max_upload_size'}, '==', 2, 'read max_upload_size from config');

# Windows gets confused with the case, it seems that it only likes uppercase environment variables
if($^O ne 'MSWin32') {
	subtest 'Environment test' => sub {
		local $ENV{'CGI::Info::max_upload_size'} = 3;

		$obj = CGI::Info->new(config_file => $config_file);

		ok($obj, 'Object was created successfully');
		isa_ok($obj, 'CGI::Info');
		cmp_ok($obj->{'max_upload_size'}, '==', 3, 'read max_upload_size from environment');
	}
};

# Nonexistent config file is ignored
throws_ok {
	CGI::Info->new(config_file => '/nonexistent/path/to/config.yml');
} qr/File not readable/, 'Throws error for nonexistent config file';

# Malformed config file (not a hashref)
my ($badfh, $badfile) = tempfile();
print $badfh "--- Just a list\n- foo\n- bar\n";
close $badfh;

throws_ok {
	CGI::Info->new(config_file => $badfile);
} qr/Can't load configuration from/, 'Throws error if config is not a hashref';

# Config file exists but has no key for the class
my $nofield_file = File::Spec->catdir($tempdir, 'nokey.yml');
DumpFile($nofield_file, {
	NotTheClass => { max_upload_size => 4 }
});
$obj = CGI::Info->new(config_file => $nofield_file);
ok($obj, 'Object created with config that lacks class key');
cmp_ok($obj->{'max_upload_size'}, '==', 512 * 1024, 'Falls back to default if class key missing');

# The global section is read
my $global_file = File::Spec->catdir($tempdir, 'global.yml');
DumpFile($global_file, {
	global => { max_upload_size => 4 }
});
$obj = CGI::Info->new(config_file => $global_file);
ok($obj, 'Object created with config that includes a global section');
cmp_ok($obj->{'max_upload_size'}, '==', 4, 'The global section is used');

# config_dirs is honoured
DumpFile($global_file, {
	global => { max_upload_size => 5 }
});
$obj = CGI::Info->new(config_dirs => [$tempdir], config_file => 'global.yml');
ok($obj, 'Object created with config that includes a global section');
cmp_ok($obj->{'max_upload_size'}, '==', 5, 'The global section is used');

done_testing();
