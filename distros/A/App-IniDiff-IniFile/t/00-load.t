#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::IniDiff::IniFile' ) || print "Bail out!\n";
}

diag( "Testing App::IniDiff::IniFile $App::IniDiff::IniFile::VERSION, Perl $], $^X" );
