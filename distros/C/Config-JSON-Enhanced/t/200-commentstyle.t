#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use List::Util 'shuffle';

our $VERSION = '0.10';

use Config::JSON::Enhanced;

my $jsonstr = <<'EOJ';
INSERTCOMMENT0
{
        INSERTCOMMENT1
	"a" : [1,2,3],
	"b" : {
                INSERTCOMMENT2
		"c" : "d",
                INSERTCOMMENT3
		"e" : {"x":1}
	},
	"f" : "hello"
        INSERTCOMMENT4
}
INSERTCOMMENT5
EOJ

my @commentstyles = (
	'C','CPP','shell',
	'custom(<<<)(>>)','custom(%%%)(%%%)',
	'custom(%%%)(%%)','custom(%%)(%%%)',
	'custom(REM)()',
);
my $Ncommentstyles = @commentstyles;

my %comments = ( map { "I am Comment".$_ => 1 } 0..5 );

for (0..100){
	my $N = 1 + int rand($Ncommentstyles-1);
	my @whatstyles = (shuffle @commentstyles)[0..$N];
	my $commentstyle = join(',', @whatstyles);
	my $jsonstrcp = $jsonstr;
	for my $ac (@whatstyles){
		for(my $i=0;$i<=5;$i++){
			if( $ac eq 'C' ){
				$jsonstrcp =~ s!\bINSERTCOMMENT${i}\b!/* I am a comment ${i} */!g
			} elsif( $ac eq 'CPP' ){
				$jsonstrcp =~ s!\bINSERTCOMMENT${i}\b!// I am a comment ${i}!g
			} elsif( $ac eq 'shell' ){
				$jsonstrcp =~ s!\bINSERTCOMMENT${i}\b!# I am a comment ${i}!g
			} elsif( $ac =~ /^custom\((.+?)\)\((.*?)\)/ ){
				my $op = $1; my $cl = $2;
				$jsonstrcp =~ s!\bINSERTCOMMENT${i}\b!${op} I am a comment ${i} ${cl}!g
			} else { BAIL_OUT "unknown comment style '$ac'" }
		}
		my $json = config2perl({
			'string' => $jsonstrcp,
			'commentstyle' => $commentstyle,
			'variable-substitutions' => {},
			#'debug' => 1,
		});
		ok(defined $json, 'config2perl()'." : called with commentstyle '$commentstyle' and got defined result.") or BAIL_OUT;
		is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

		ok(exists($json->{'a'}), 'config2perl()'." : called and result contains required key.");
		ok(defined($json->{'a'}), 'config2perl()'." : called and result contains required key and it is defined.");
		is(ref($json->{'a'}), 'ARRAY', 'config2perl()'." : called and result contains required key and it is an ARRAY.");

		ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");
		ok(defined($json->{'b'}), 'config2perl()'." : called and result contains required key and it is defined.");
		is(ref($json->{'b'}), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");

		ok(exists($json->{'f'}), 'config2perl()'." : called and result contains required key.");
		ok(defined($json->{'f'}), 'config2perl()'." : called and result contains required key and it is defined.");
		is(ref($json->{'f'}), '', 'config2perl()'." : called and result contains required key and it is a scalar string.");
	}
}
done_testing();
