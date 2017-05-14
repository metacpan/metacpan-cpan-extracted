#!/usr/bin/env perl
use inc::Module::Install 1.02;

name 'Catalyst-Plugin-BigSitemap';
abstract 'A Catalyst Plugin for Sitemaps up to 2.5 billion urls.';
license 'perl';
version '0.9';
perl_version '5.010002';
all_from 'lib/Catalyst/Plugin/BigSitemap.pm';

requires 'Catalyst'; # I don't think this should have any version-specific dependencies.. any version of catalyst should do.
requires 'WWW::Sitemap::XML'=> '1.121160';
requires 'Modern::Perl'     => '1.20121103';
requires 'Try::Tiny'        => '0.18';
requires 'Moose'            => '2.1005';
requires 'Carp'             => '1.32';
requires 'Path::Class'      => '0.32';

test_requires 'Test::More'  => '0.47';

WriteAll();