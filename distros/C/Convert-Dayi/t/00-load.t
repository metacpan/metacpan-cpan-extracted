#!perl
use lib 'lib';

use utf8;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Convert::Dayi' );
}

diag( "Testing Convert::Dayi $Convert::Dayi::VERSION, Perl $], $^X" );

use Convert::Dayi qw(as_ascii as_dayi from_ascii);


is( as_ascii("大易 abc 中文") , 'v db/  abc o1 kx ' );
is( as_dayi("大易abc中文") , '禾 日馬竹 abc口言 立水 ' );
is( from_ascii('v1 ubuntu db/1') , '大ubuntu易' );
