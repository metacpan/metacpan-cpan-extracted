# This -*- perl -*- script makes the Makefile

use strict;
use warnings;
use 5.005;
use inc::Module::Install;

name		'Authen-SASL';
abstract	'SASL Authentication framework';
author		'Graham Barr <gbarr@pobox.com>';
version_from	'lib/Authen/SASL.pm';
license		'perl';
repository	'http://github.com/gbarr/perl-authen-sasl';

perl_version	5.005;

test_requires	'Test::More' => 0;
requires	'Digest::MD5'  => 0;
requires	'Digest::HMAC_MD5'  => 0;
recommends	'GSSAPI'  => 0;

tests_recursive;

WriteAll();
