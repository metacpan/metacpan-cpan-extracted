#!/usr/bin/perl

use inc::Module::Install;

name		('App-CLI');
author		('Chia-liang Kao <clkao@clkao.org>');
# author		('Cornelius <cornelius.howl@gmail.com>');
abstract_from	('lib/App/CLI.pm');
license		('perl');
version_from	('lib/App/CLI.pm');

requires(
    'Locale::Maketext::Simple' => 0,
    'Getopt::Long'             => '2.35',
    'Pod::Simple::Text'        => 0,
);

auto_install();

# WriteAll( sign => 1 );
WriteAll( );
