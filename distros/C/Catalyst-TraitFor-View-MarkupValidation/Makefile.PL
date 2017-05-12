use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-TraitFor-View-MarkupValidation';
all_from 'lib/Catalyst/TraitFor/View/MarkupValidation.pm';

requires 'Moose';
requires 'Template';
requires 'WebService::Validator::HTML::W3C';
requires 'Syntax::Highlight::Engine::Kate';
requires 'namespace::autoclean';
requires 'Memoize';
requires 'Carp';
requires 'Catalyst::Action::RenderView';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';
build_requires 'Catalyst::ScriptRunner';
build_requires 'Test::MockObject';
build_requires 'WebService::Validator::HTML::W3C::Error';
build_requires 'FindBin';
build_requires 'Catalyst::View::TT';
build_requires 'ok';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://github.com/dorward/Catalyst-TraitFor-View-MarkupValidation.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/TraitFor/View/MarkupValidation.pm > README")
        and die $!;
}

WriteAll();
