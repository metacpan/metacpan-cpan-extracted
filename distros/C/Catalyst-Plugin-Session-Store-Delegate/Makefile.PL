#!/usr/bin/env perl

use inc::Module::Install 0.87;
use strict;
use warnings;

all_from 'lib/Catalyst/Plugin/Session/Store/Delegate.pm';
name 'Catalyst-Plugin-Session-Store-Delegate';
requires 'Catalyst::Plugin::Session' => '0.27';
requires 'Moose';
requires 'namespace::clean';
requires 'MooseX::Emulate::Class::Accessor::Fast';
test_requires 'Test::More' => '0';
test_requires 'Test::use::ok' => '0';
requires 'MRO::Compat' => '0';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Session-Store-Delegate/';

WriteAll;

