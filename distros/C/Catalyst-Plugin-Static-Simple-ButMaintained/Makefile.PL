use strict;
use warnings;
use inc::Module::Install 0.91;

resources repository => 'git://github.com/EvanCarroll/Catalyst-Plugin-Static-Simple.git';

name 'Catalyst-Plugin-Static-Simple-ButMaintained';
all_from 'lib/Catalyst/Plugin/Static/Simple/ButMaintained.pm';

requires 'Catalyst::Runtime' => '5.80008';
requires 'MIME::Types' => '1.25';
requires 'Test::More';
requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::autoclean';

test_requires 'Test::More';

test_requires 'Test::Pod' => '1.14';
test_requires 'Test::Pod::Coverage' => '1.04';

if( can_use 'Catalyst::Plugin::SubRequest' ) {
    unless( can_use 'Catalyst::Plugin::SubRequest' => '0.08' ) {
        print "** WARNING **\n"
            . "You appear to have a version of Catalyst::Plugin::SubRequest "
            . "older than 0.08.\n"
            . "You must upgrade to SubRequest 0.08 or later if you use it "
            . "in any applications with Static::Simple::ButMaintained.\n";
        requires 'Catalyst::Plugin::SubRequest' => '0.08';
    }
}

auto_install;

WriteAll;
