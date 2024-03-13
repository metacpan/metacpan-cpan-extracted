#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use File::Temp qw/tempfile tempdir/;
use File::Spec;

our $VERSION = '0.10';

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
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
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

# save data to a file
my $tmpdir = tempdir(CLEANUP => 1);
ok(-d $tmpdir, "Temp dir '$tmpdir' created.") or BAIL_OUT;
my $infile = File::Spec->catdir($tmpdir, 'simple.ejson');
my $FH;
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $simple_json; close $FH;

#############################################################
# read+parse from filehandle
#############################################################

ok(open($FH, '<:utf8', $infile), "Opened tempfile '$infile' for reading test JSON.") or BAIL_OUT("no ".$!);
$json = config2perl({
	'filehandle' => $FH,
        'commentstyle' => 'CPP,C',
        'variable-substitutions' => {},
});
close $FH;
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
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

#############################################################
# read+parse content we just wrote using the 'filename' param
#############################################################
$json = config2perl({
	'filename' => $infile,
        'commentstyle' => 'CPP,C',
        'variable-substitutions' => {},
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
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
