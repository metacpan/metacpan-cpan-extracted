#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

our $VERSION = '0.02';

use Config::JSON::Enhanced;

my $simple_json = <<'EOJ';
{
	"a" : [1,2,3],
	"b" : {
		"c" : "d",
		"e" : {"x":1}
	},
	"f" : "hello"
}
EOJ

my $json = config2perl({
	'string' => $simple_json,
	'commentstyle' => 'CPP,C',
	'variable-substitutions' => {},
});
ok(defined $json, 'config2perl()'." : called and got defined result.");
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

done_testing();
