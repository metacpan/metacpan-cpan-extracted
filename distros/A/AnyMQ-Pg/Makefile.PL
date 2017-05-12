#!perl

sub readme_from   { }
sub auto_set_repository { }

use inc::Module::Install;

name 'AnyMQ-Pg';
all_from 'lib/AnyMQ/Pg.pm';
readme_from 'lib/AnyMQ/Pg.pm';
build_requires 'Test::More';
requires 'Test::More';
requires 'AnyMQ' => '0.30';
requires 'JSON';
requires 'Try::Tiny';
requires 'Any::Moose';
requires 'AnyEvent::Pg' => 0.04;

auto_include_deps;
auto_set_repository;
WriteAll;
