#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name '<% dist_module %>';
all_from 'lib/<% dist_module %>.pm';

requires 'CatalystX::Crudite' => '<% crudite_version %>';

test_requires 'App::ForkProve';
test_requires 'DBICx::TestDatabase';
test_requires 'Plack::Middleware::Debug';
test_requires 'Plack::Middleware::Debug::DBIC::QueryLog';
test_requires 'Test::More' => '0.88';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Try::Tiny';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
