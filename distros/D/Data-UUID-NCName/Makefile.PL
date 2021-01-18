use inc::Module::Install;

name        'Data-UUID-NCName';
abstract    'Make valid NCName tokens which are also UUIDs.';
author      q{Dorian Taylor <dorian@cpan.org>};
readme_from 'lib/Data/UUID/NCName.pm';
all_from    'lib/Data/UUID/NCName.pm';
license     'apache';
resources repository => 'https://github.com/doriantaylor/p5-data-uuid-ncname';

requires 'MIME::Base64'   => '3.15';
requires 'MIME::Base32'   => '1.303';
requires 'Encode::Base58' => '0.01';
requires 'UUID::Tiny'     => '1.04';
requires 'Type::Tiny'     => '1.002002';

build_requires 'Test::More';
#test_requires 'Data::UUID';

install_script 'script/uuid-ncname';

auto_install;

WriteAll;

