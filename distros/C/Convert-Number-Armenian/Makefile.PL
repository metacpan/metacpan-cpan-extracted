#!/usr/bin/perl
use 5.008003;
use inc::Module::Install;
author( 'Tara L Andrews <aurum@cpan.org>' );
license( 'perl' );
all_from( 'lib/Convert/Number/Armenian.pm' );
requires( 'perl' => '5.008003' );
test_requires( 'Test::More::UTF8' );
test_requires( 'Test::Warn' );
&WriteAll;
