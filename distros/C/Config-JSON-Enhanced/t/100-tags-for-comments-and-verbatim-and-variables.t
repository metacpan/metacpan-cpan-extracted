#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use File::Temp qw/tempfile tempdir/;
use File::Spec;
use Data::Roundtrip qw/json2perl perl2dump no-unicode-escape-permanently/;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

my $simple_json = <<'EOJ';
__COOPTAG__ this is a comment which may confuse regex __COCLTAG__
{
	"a" : "hello __TVOPTAG__ var1 __TVCLTAG__",
	"b" :
__COOPTAG__ comment to denote the begin of verbatim section __COCLTAG__
__VSOPTAG__ begin-verbatim-section __VSCLTAG__
i am a verbatim section:
__TVOPTAG__ var2 __TVCLTAG__
__COOPTAG__ this must remain __COCLTAG__
and goodbye from verbatim section.
__VSOPTAG__ end-verbatim-section __VSCLTAG__
__COOPTAG__ comment to denote the end of verbatim section __COCLTAG__
}
EOJ

my @testparams = (
  {
	'tags-comment' => ['</*','*/>'],
	'tags-rest' => ['</+','+/>'],
	'variable-substitutions' => {
		'var1' => '***',
		'var2' => 'hehehe',
	}
  },
  {
	'tags-comment' => ['\\\\*','*\\\\'],
	'tags-rest' => ['!!*','*!!'],
	'variable-substitutions' => {
		'var1' => 'hahaha',
		'var2' => '***',
	}
  },
  {
	'tags-comment' => ['/*/+/?','?/+/*/'],
	'tags-rest' => ['***!', '!***'],
	'variable-substitutions' => {
		'var1' => 'hahaha',
		'var2' => '+++',
	}
  },
  {
	'tags-comment' => ['---','+++'],
	'tags-rest' => ['***','///'],
	'variable-substitutions' => {
		'var1' => '}',
		'var2' => '{',
	}
  },
);

my ($s, $simple_json_new, $atestparam);
for $atestparam (@testparams){
	$simple_json_new = $simple_json;
	# substitute the tags of the comments
	$s = $atestparam->{'tags-comment'}->[0];
	$simple_json_new =~ s/__COOPTAG__/${s}/g;
	$s = $atestparam->{'tags-comment'}->[1];
	$simple_json_new =~ s/__COCLTAG__/${s}/g;
	# substitute the tags of the variables
	$s = $atestparam->{'tags-rest'}->[0];
	$simple_json_new =~ s/__TVOPTAG__/${s}/g;
	$s = $atestparam->{'tags-rest'}->[1];
	$simple_json_new =~ s/__TVCLTAG__/${s}/g;
	# substitute the tags of the verbatim sections
	$s = $atestparam->{'tags-rest'}->[0];
	$simple_json_new =~ s/__VSOPTAG__/${s}/g;
	$s = $atestparam->{'tags-rest'}->[1];
	$simple_json_new =~ s/__VSCLTAG__/${s}/g;

	my $json = config2perl({
		'string' => $simple_json_new,
		'commentstyle' => 'custom('.$atestparam->{'tags-comment'}->[0].')('.$atestparam->{'tags-comment'}->[1].')',
		'tags' => $atestparam->{'tags-rest'},
		'variable-substitutions' => $atestparam->{'variable-substitutions'},
	});
	ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
	is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
diag perl2dump($json);

	ok(exists($json->{'a'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'a'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'a'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");

	ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'b'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'b'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");

	# save data to a file
	my $tmpdir = tempdir(CLEANUP => 1);
	ok(-d $tmpdir, "Temp dir '$tmpdir' created.") or BAIL_OUT;
	my $infile = File::Spec->catdir($tmpdir, 'simple.ejson');
	my $FH;
	ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
	print $FH $simple_json_new; close $FH;

	#############################################################
	# read+parse from filehandle
	#############################################################

	ok(open($FH, '<:utf8', $infile), "Opened tempfile '$infile' for reading test JSON.") or BAIL_OUT("no ".$!);
	$json = config2perl({
		'filehandle' => $FH,
		'commentstyle' => 'custom('.$atestparam->{'tags-comment'}->[0].')('.$atestparam->{'tags-comment'}->[1].')',
		'tags' => $atestparam->{'tags-rest'},
		'variable-substitutions' => $atestparam->{'variable-substitutions'},
	});
	close $FH;
	ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
	is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

	ok(exists($json->{'a'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'a'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'a'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");

	ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'b'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'b'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");


	#############################################################
	# read+parse content we just wrote using the 'filename' param
	#############################################################
	$json = config2perl({
		'filename' => $infile,
		'commentstyle' => 'custom('.$atestparam->{'tags-comment'}->[0].')('.$atestparam->{'tags-comment'}->[1].')',
		'tags' => $atestparam->{'tags-rest'},
		'variable-substitutions' => $atestparam->{'variable-substitutions'},
	});
	ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
	is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

	ok(exists($json->{'a'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'a'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'a'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");

	ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");
	ok(defined($json->{'b'}), 'config2perl()'." : called and result contains required key and it is defined.");
	is(ref($json->{'b'}), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");

}

done_testing();
