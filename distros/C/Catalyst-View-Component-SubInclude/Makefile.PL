use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-View-Component-SubInclude';
all_from 'lib/Catalyst/View/Component/SubInclude.pm';

requires 'Catalyst::Runtime' => '5.80014';
requires 'Catalyst::Plugin::SubRequest';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Types';
requires 'Carp';
requires 'namespace::clean';
requires 'LWP::UserAgent';
requires 'List::MoreUtils';
requires 'URI';

test_requires 'Test::More' => '0.88';
test_requires 'Catalyst::View::TT';
test_requires 'Catalyst::Action::RenderView';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';
author_tests 't/author';

catalyst;

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-View-Component-SubInclude';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/View/Component/SubInclude.pm > README")
        and die $!
}

auto_install;
WriteAll;
