#!perl

#  Load
#
use Test::More qw(no_plan);
use_ok( 'Markdown::Pod::Embed' );
$_='caller value';
use_ok( 'ASPEER::MakeMaker::Markdown::Pod' );
is( $_, 'caller value', 'loading module preserves caller default variable' );
ok( ASPEER::MakeMaker::Markdown::Pod->isa('ASPEER::MakeMaker'),
    'plugin inherits ASPEER::MakeMaker' );
ok( exists $INC{'ASPEER/MakeMaker/MM/Import.pm'},
    'plugin inherits the shared MakeMaker integration' );
use_ok( 'ASPEER::MakeMaker::Markdown::Pod::MM' );
use_ok( 'ASPEER::MakeMaker::MM::Util' );
use_ok( 'ASPEER::MakeMaker::Markdown::Pod::Constant' );
use_ok( 'ASPEER::MakeMaker::MM::Import' );
