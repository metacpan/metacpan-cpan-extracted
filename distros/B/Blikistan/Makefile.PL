#!/usr/bin/perl -w
use warnings;
use strict;
use inc::Module::Install;

name            'Blikistan';
author          'Luke Closs <cpan@5thplane.com>';
license         'perl';
version_from    'lib/Blikistan.pm';

build_requires 'Test::More'           => '0.42';
requires 'Socialtext::Resting::Utils' => '0.11';
requires 'Socialtext::Resting'        => '0.20';
requires 'Template';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
