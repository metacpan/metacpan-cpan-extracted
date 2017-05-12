#!/usr/bin/perl

use strict;
use inc::Module::Install;

name		'Acme-ComeFrom';
all_from        'lib/Acme/ComeFrom.pm';
requires        'Filter::Simple' => 0.70;
requires        'Hook::LexWrap'  => 0.20;
build_requires  'Test::More';

auto_provides;
auto_include_deps;

sign; WriteAll;
