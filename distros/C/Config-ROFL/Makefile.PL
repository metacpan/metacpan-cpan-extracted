use inc::Module::Install;
use strict;
use warnings;

name 'Config-ROFL';
abstract 'Yet another config module';
author q{Nicolas Mendoza <mendoza@pvv.ntnu.no>};
license 'perl';
version '1.10';

configure_requires 'Module::Install';

build_requires 'Test::More';

requires 'Cwd';
requires 'Carp';
requires 'Config::General';
requires 'Cpanel::JSON::XS' => '4.04';
requires 'Config::ZOMG';
requires 'Config::Any' => 0.33;
requires 'Data::Rmap';
requires 'File::Share';
requires 'File::Spec';
requires 'List::Util' => '1.33';    # 1.33 needed for 'any'
requires 'Moo';
requires 'MooX::Singleton';
requires 'namespace::clean';
requires 'Path::Tiny';
requires 'Types::Standard';
requires 'YAML::XS';

test_requires 'File::Share';
test_requires 'Test::More';
test_requires 'Test::Output';

auto_install;

WriteAll;

