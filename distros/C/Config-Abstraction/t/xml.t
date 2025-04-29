use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

my $test_dir = tempdir();

write_file(File::Spec->catdir($test_dir, 'xml_test'), <<'XML');
<?xml version="1.0"?>
<config>
	<UserName>njh</UserName>
</config>
XML

my $config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	config_file => 'xml_test'
);

diag(Data::Dumper->new([$config])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_ok($config->get('UserName'), 'eq', 'njh', 'XML can be read in from a file with an XML header');

$config = Config::Abstraction->new(
	config_dirs => [''],	# It's an absolute path
	config_file => File::Spec->catdir($test_dir, 'xml_test')
);

ok(defined($config));
cmp_ok($config->get('UserName'), 'eq', 'njh', 'absolute path to config_file works');

write_file(File::Spec->catdir($test_dir, 'xml_test'), <<'XML');
<config>
	<UserName>nan</UserName>
</config>
XML

$config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	config_files => ['foo', 'xml_test']
);

diag(Data::Dumper->new([$config])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_ok($config->get('UserName'), 'eq', 'nan', 'XML can be read in from a file with no XML header');
cmp_ok($config->all()->{'UserName'}, 'eq', 'nan', 'XML can be read in from a file with no XML header');

done_testing();
