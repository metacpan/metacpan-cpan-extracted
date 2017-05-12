use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

perl_version '5.8.1';

name 'Catalyst-Action-Serialize-Data-Serializer';
all_from 'lib/Catalyst/Action/Serialize/Data/Serializer.pm';

requires('Catalyst::Action::REST' => '1.08');
requires 'Moose' => '1.03';
requires 'namespace::autoclean';
requires('Catalyst::Runtime'         => '5.80030');
requires('Data::Serializer'          => '0.36');

test_requires 'Test::More' => '0.88';

authority 'MSTROUT';
author_requires 'Test::Pod' => 1.14;
author_requires 'Module::Info';
author_requires 'File::Find::Rule';

author_tests 'xt/';

auto_install;

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Action/Serialize/Data/Serializer.pm > README")
        and die $!;
}

repository
   'git://git.shadowcat.co.uk/catagits/Catalyst-Action-Serialize-Data-Serializer.git';

add_metadata( x_authority => 'cpan:BOBTFISH' );

WriteAll;

