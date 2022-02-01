use strict;
use warnings;

use App::CPAN::Get::Utils qw(process_module_name_and_version);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my ($ret_name, $ret_version_range) = process_module_name_and_version('Module');
is($ret_name, 'Module', 'Parse module name (Module).');
is($ret_version_range, undef, 'Parse module version range (Module).');

# Test.
($ret_name, $ret_version_range) = process_module_name_and_version('Module@1.23');
is($ret_name, 'Module', 'Parse module name (Module@1.23).');
is($ret_version_range, '== 1.23', 'Parse module version range (Module@1.23).');

# Test.
($ret_name, $ret_version_range) = process_module_name_and_version('Module~1.23');
is($ret_name, 'Module', 'Parse module name (Module~1.23).');
is($ret_version_range, '1.23', 'Parse module version range (Module~1.23).');
