use strict;
use warnings;

BEGIN { push @INC, '.' unless $INC[-1] eq '.'; }

use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Plugin-Static-Simple';
all_from 'lib/Catalyst/Plugin/Static/Simple.pm';

requires 'Catalyst::Runtime' => '5.80008';
requires 'MIME::Types' => '2.03';
requires 'Test::More';
requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::autoclean';

test_requires 'Test::More';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

author_tests 't/author';

if( can_use 'Catalyst::Plugin::SubRequest' ) {
    unless( can_use 'Catalyst::Plugin::SubRequest' => '0.08' ) {
        print "** WARNING **\n"
            . "You appear to have a version of Catalyst::Plugin::SubRequest "
            . "older than 0.08.\n"
            . "You must upgrade to SubRequest 0.08 or later if you use it "
            . "in any applications with Static::Simple.\n";
        requires 'Catalyst::Plugin::SubRequest' => '0.08';
    }
}

auto_install;
resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Plugin-Static-Simple.git';

WriteAll;
