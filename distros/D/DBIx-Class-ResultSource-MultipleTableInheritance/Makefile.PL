use strict;
use warnings;
use inc::Module::Install;

if ($Module::Install::AUTHOR) {
    system(
        'pod2text lib/DBIx/Class/ResultSource/MultipleTableInheritance.pm > README'
    );
    system(
        'pod2html lib/DBIx/Class/ResultSource/MultipleTableInheritance.pm > README.html'
    );
}

name 'DBIx-Class-ResultSource-MultipleTableInheritance';
all_from 'lib/DBIx/Class/ResultSource/MultipleTableInheritance.pm';

configure_requires 'DBIx::Class' => '0.08191';

requires 'Carp::Clan';
requires 'DBD::Pg';
requires 'DBIx::Class';
requires 'Method::Signatures::Simple';
requires 'String::TT';
requires 'aliased';
requires 'namespace::autoclean';
requires 'parent';
requires 'SQL::Translator' => '0.11016';

test_requires 'Test::More' => '0.98';
test_requires 'Module::Find';

auto_install;
WriteAll;
