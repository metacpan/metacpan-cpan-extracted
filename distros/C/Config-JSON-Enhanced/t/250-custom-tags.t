#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

our $VERSION = '0.10';

use Config::JSON::Enhanced;

my $jsonstr = <<'EOJ';
{
	"a" : [1,2,3],
	"b" : {
		"c" : "[: var1 :]",
		"e" : {"x":[:var2:]}
	},
	"f" : "hello"
}
EOJ

my $json = config2perl({
	'string' => $jsonstr,
	'commentstyle' => 'CPP,C',
	'tags' => [ '[:', ':]' ],
	'variable-substitutions' => {
		'var1' => 'hello',
		'var2' => 42
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'a'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'a'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'a'}), 'ARRAY', 'config2perl()'." : called and result contains required key and it is an ARRAY.");

ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'b'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'b'}), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
my $B = $json->{'b'};
ok(exists($B->{'c'}), 'config2perl()'." : called and result contains required key.");
ok(defined($B->{'c'}), 'config2perl()'." : called and result contains required key.");
is($B->{'c'}, 'hello', 'config2perl()'." : called and result contains required key.");
ok(exists($B->{'e'}), 'config2perl()'." : called and result contains required key.");
ok(defined($B->{'e'}), 'config2perl()'." : called and result contains required key.");
is($B->{'e'}->{'x'}, 42, 'config2perl()'." : called and result contains required key.");

ok(exists($json->{'f'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'f'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'f'}), '', 'config2perl()'." : called and result contains required key and it is a scalar string.");

done_testing();
