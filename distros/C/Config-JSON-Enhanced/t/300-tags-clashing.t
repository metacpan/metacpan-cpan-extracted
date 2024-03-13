#!perl

use 5.010;
use strict;
use warnings;

our $VERSION = '0.10';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use Config::JSON::Enhanced;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

my $jsonstr = <<'EOJ';
{
	"a" : "hello"
}
EOJ

my @tests = (
  {
	'commentstyle' => 'custom(<:*)(*:>)',
	'tags' => [ '<:*', '*:>' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(<:*)(!!*:>)',
	'tags' => [ '<:*', '*:>!!' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(<:*)(*:>)',
	'tags' => [ '*:>', 'xxx' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => [ '*:>', 'xxx' ], 
	'tags' => 'custom(<:*)(*:>)',
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(<:*)(*:>)',
	'tags' => [ '<<<:*>>', 'xxx' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(<:*)(*:>)',
	'tags' => [ 'xxx', '<<<*:>>>>' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(<:*)(*:>)',
	'tags' => [ '<<<:*>>', 'xxx' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(xxx)(<<<*:>>>>)',
	'tags' => [ '<:*', '*:>' ], 
	'result' => 'fail'
  },
  {
	'commentstyle' => 'custom(XX)(YY)',
	'tags' => [ 'AA', 'BB' ], 
	'result' => 'success'
  },
);

for my $atest (@tests){
	my $json = config2perl({
		'string' => $jsonstr,
		'commentstyle' => $atest->{'commentstyle'},
		'tags' => $atest->{'tags'},
	});
	if( $atest->{'result'} eq 'success' ){
		ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT(perl2dump($atest)."for above test");
		is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
	} else {
		ok( ! defined $json, 'config2perl()'." : called and got failed result AS EXPECTED.") or BAIL_OUT(perl2dump($atest)."for above test");;
	}
}

done_testing();
