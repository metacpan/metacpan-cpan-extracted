use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-TraitFor-Controller-RenderView';
all_from 'lib/Catalyst/TraitFor/Controller/RenderView.pm';

requires 'Moose';
requires 'MooseX::MethodAttributes::Role';
requires 'namespace::autoclean';

requires 'Catalyst::Action::RenderView' => '0.13';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'CatalystX::Component::Traits';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://github.com/bobtfish/catalyst-traitfor-controller-renderview.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/TraitFor/Controller/RenderView.pm > README")
        and die $!;
}

WriteAll();
