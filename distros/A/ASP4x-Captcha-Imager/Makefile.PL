use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4x-Captcha-Imager';
perl_version '5.008001';
license 'perl';
all_from 'lib/ASP4x/Captcha/Imager.pm';

test_requires 'Test::More'  => '0.77';
test_requires 'HTML::Form'  => 0;

requires 'ASP4'             => '1.046';
requires 'Imager'           => '0.71';
requires 'Digest::MD5'      => 0;

tests_recursive();
WriteAll();

