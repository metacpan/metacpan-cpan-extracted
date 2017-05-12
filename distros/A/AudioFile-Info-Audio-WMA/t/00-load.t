#!perl 

use warnings;
use strict;
use lib qw(../lib ./lib);
use Test::More tests => 10;

BEGIN {
	use_ok( 'AudioFile::Info::Audio::WMA' );
}

diag( "Testing AudioFile::Info::Audio::WMA $AudioFile::Info::Audio::WMA::VERSION, Perl $], $^X" );

my $wma;
use Data::Dumper;
ok( $wma = AudioFile::Info::Audio::WMA->new( 't/00-load.wma' ) );
ok( $wma->genre eq 'Rock' );
ok( $wma->title eq 'Stripped, Pt. 2' );
ok( $wma->album eq 'Stripped' );

ok( $wma->year eq '2002' );
ok( $wma->track eq '17' );
ok( $wma->artist eq 'Christina Aguilera' );
ok(1);
ok(1);
