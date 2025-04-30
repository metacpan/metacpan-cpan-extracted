use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

my $test_dir = tempdir();
my $test_file = File::Spec->catdir($test_dir, 'test');

write_file(File::Spec->catdir($test_file), <<'FIN');
files	/etc/group,/etc/passwd
FIN

my $config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	config_file => 'test',
);

ok(defined($config));
diag(Data::Dumper->new([$config])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_ok(@{$config->get('files')}[0], 'eq', '/etc/group', 'testing');

done_testing();
