#!/usr/bin/env perl
use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Authentication-AuthTkt';
perl_version '5.8.9';
all_from 'lib/Catalyst/Authentication/AuthTkt.pm';

requires 'Catalyst'                         => 5.7014;
requires 'Apache::AuthTkt'                  => 0.08;
requires 'Catalyst::Plugin::Authentication' => 0.10007;
requires 'Data::Dump'                       => 0;
requires 'Config::General'                  => 0;
requires 'Moose'                            => 0;

test_requires 'Test::More'                               => 0;
test_requires 'Catalyst::Plugin::Static::Simple'         => 0;
test_requires 'Catalyst::Plugin::ConfigLoader'           => 0;
test_requires 'Catalyst::Plugin::Session'                => 0;
test_requires 'Catalyst::Plugin::Session::Store::Dummy'  => 0;
test_requires 'Catalyst::Plugin::Session::State::Cookie' => 0;
test_requires 'HTTP::Cookies'                            => 0;

license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/catalyst-authentication-authtkt';
bugtracker
    'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-AuthTkt';
repository 'http://github.com/karpet/catalyst-authentication-authtkt';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Authentication-AuthTkt-*' },
);
