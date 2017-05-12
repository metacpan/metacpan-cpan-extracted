use strict;
use warnings;
use inc::Module::Install 0.91;

name('CatalystX-Starter');
all_from('lib/CatalystX/Starter.pm');

requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Runtime' => '5.80015';
requires 'Catalyst::Devel';
requires 'Test::More' => '0.88';
requires 'Test::Pod' => '1.14';
requires 'Test::Pod::Coverage' => '1.04';
requires 'File::ShareDir';
requires 'File::Copy::Recursive';
requires 'File::Slurp';

build_requires 'File::pushd';
build_requires 'Directory::Scratch';
build_requires 'Test::TableDriven';
build_requires 'Test::Exception';

install_script('bin/catalystx-starter');

resources repository => 'git://github.com/bobtfish/catalystx-starter.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/Starter.pm > README")
        and die $!;
}

no_index directory => 'lib/auto';

WriteAll();
