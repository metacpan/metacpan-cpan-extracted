#!/usr/local/bin/perl
use strict;

use Getopt::Std;
use Test::Assertions qw(test);
use Log::Trace;
use lib qw(./lib ../lib);
use Config::Wrest;

use vars qw($opt_t $opt_T);

eval "use Template;";
if ($@) {
	print "1..1\n";
	print "ok 1 (Skipping all - TemplateToolkit module required for testing templated configurations)\n";
	exit(0);
}

plan tests;

#Move into the t directory if we aren't already - makes the test work from anywhere
chdir($1) if($0 =~ /(.*)\/(.*)/);

ASSERT($Config::Wrest::VERSION,"compiled version $Config::Wrest::VERSION");

#We allow tracing to be enabled with -t or -T for different verbosity levels
#We do this AFTER we compile our module

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	deep_import Log::Trace qw(print);
}

my $conf_one = 'data/Reader_directives1.cfg';

$ENV{'UNIT_TEST'} = 'Davey';

# note - all options are OFF
my $cr = new Config::Wrest( TemplateBackend => "TemplateToolkit", UseQuotes => 0, Escapes => 0, Variables => { 'SetInPerl' => 42, 'Deep' => { 'Thought' => 'done' } } );
DUMP($cr);
my $vardata = $cr->parse_file($conf_one);
DUMP('Variables', $vardata);
ASSERT(ref($cr) eq 'Config::Wrest', 'Created object ok');

#check each kind of block, in turn
ASSERT(EQUAL($vardata->{'none'}, {
	aaa => 'aaa',
	aab => '\'aab\'',
	aac => '"aac"',
	aad => 'aa d',
	aae => 'aa%65',
	aaf => 'foo[% bar %]baz'
	}), 'no options set');
ASSERT(EQUAL($vardata->{'esc'}, {
	aaa => 'aaa',
	aab => '\'aab\'',
	aac => '"aac"',
	aad => 'aa d',
	aae => 'aae',
	aaf => 'foo[% bar %]baz'
	}), 'escape option set');
ASSERT(EQUAL($vardata->{'quot'}, {
	aaa => 'aaa',
	aab => 'aab',
	aac => 'aac',
	aad => 'aa d',
	aae => 'aae',
	aaf => 'foo[% bar %]baz'
}), 'quoting option set');
ASSERT(EQUAL($vardata->{'subs'}, {
	aaa => 'aaa',
	aab => 'aab',
	aac => 'aac',
	aad => 'aa d',
	aae => 'aae',
	aaf => 'foobaz',
	aag => 'fooYYZbaz',
	aah => 'baz_ht',
	aai => 'baz_YYZ_2_ht',
	aaj => 'baz_YYZ_2_ht',
	}), 'substitution option set');
ASSERT(EQUAL($vardata->{'list_single'}, [
	'hello'
	]), 'interpolated a single line which was then read correctly');
ASSERT(EQUAL($vardata->{'list_multi'}, [
	'line1',
	'line2',
	'line3'
	]), 'interpolated multiple lines which were read correctly');
ASSERT(EQUAL($vardata->{'list_esc'}, ['line1
line2
0
# a comment

']), 'interpolated using escape() creating single value');

ASSERT(EQUAL($vardata->{'included'}, 1), 'file included');
ASSERT(EQUAL($vardata->{'usingexternal'}, 'foo2112bar'), 'variable set in external file persists');
ASSERT(EQUAL($vardata->{'selfreferential1'}, 'fooYYZbaz'), 'self-referencing of variables works');
ASSERT(EQUAL($vardata->{'selfreferential2'}, ''), 'self-referencing of variables works');
ASSERT(EQUAL($vardata->{'selfreferential3'}, 'YES'), 'self-referencing of variables works');

ASSERT(EQUAL($vardata->{'perlvariables'}, 'xx42yy'), 'got data from the perl interface');
ASSERT(EQUAL($vardata->{'perlvariables2'}, 'xxdoneyy'), 'got data from the perl interface');
ASSERT(EQUAL($vardata->{'envvars'}, 'Davey'), 'got data from the environment');

#test @reference directive
ASSERT($cr->_var('_RefTest1->line', $vardata) eq '84', 'reference - correct value');
ASSERT($cr->_var('_RefTest1->nest->line', $vardata) eq '86', 'reference - correct value');
ASSERT($cr->_var('RefTest3->0->line', $vardata) eq '84', 'reference - correct value');
ASSERT($cr->_var('RefTest3->0->nest->line', $vardata) eq '86', 'reference - correct value');
ASSERT($cr->_var('RefTest3->1', $vardata) eq '86', 'reference - correct value');
ASSERT($cr->_var('_RefTest2->1->0', $vardata) eq 'Hello', 'reference - correct value');
ASSERT($cr->_var('RefTest4->1->0', $vardata) eq 'Hello', 'reference - correct value');
ASSERT($cr->_var('_RefTest2->0', $vardata) eq 'eightyseven', 'reference - correct value');
ASSERT($cr->_var('RefTest4->0', $vardata) eq 'eightyseven', 'reference - correct value');
ASSERT($cr->_var('RefTest5->six->seven->eight->line', $vardata) eq '86', 'reference - correct value');
ASSERT($cr->_var('RefCirc->foo', $vardata) eq 'bar', 'reference (circular) - correct value');
ASSERT($cr->_var('RefCirc->baz->baz->baz->foo', $vardata) eq 'bar', 'reference (circular) - correct value');


$cr = new Config::Wrest();
$vardata = $cr->deserialize("[arr]\nfoo\n\@reference arr\n[/]\n");
DUMP('Variables', $vardata);
ASSERT($cr->_var('arr->0', $vardata) eq 'foo', "correct value from cyclic data");
ASSERT($cr->_var('arr->1->0', $vardata) eq 'foo', "correct value from cyclic data");
ASSERT($cr->_var('arr->1->1->1->0', $vardata) eq 'foo', "correct value from cyclic data");

$cr = new Config::Wrest();
$vardata = $cr->deserialize("<baz>\nfoo bar\n\@reference qux baz\n</>\n");
DUMP('Variables', $vardata);
ASSERT($cr->_var('baz->foo', $vardata) eq 'bar', "correct value from cyclic data");
ASSERT($cr->_var('baz->qux->foo', $vardata) eq 'bar', "correct value from cyclic data");
ASSERT($cr->_var('baz->qux->qux->qux->qux->foo', $vardata) eq 'bar', "correct value from cyclic data");

$cr = new Config::Wrest(
	Subs => 1,
	TemplateBackend => 'TemplateToolkit',
);
$vardata = $cr->deserialize("\@set HOME 123KB\nColour Red\nLocality [% HOME %]");
DUMP('Variables', $vardata);
ASSERT($vardata->{'Locality'} eq '123KB', "correct value from TemplateToolkit data");
ASSERT($vardata->{'Colour'} eq 'Red', "correct value from TemplateToolkit data");


# Now check the behaviour of @set when the Variables data structure is re-used
$cr = new Config::Wrest( Variables => undef );
ASSERT($cr, "object created OK");

eval { $cr = new Config::Wrest( Variables => 'a', ); };
chomp($@);
ASSERT($@, "Trapped error: $@");

eval { $cr = new Config::Wrest( Variables => ['a'], ); };
chomp($@);
ASSERT($@, "Trapped error: $@");

my $variables = {
	'red' => 'star',
	'sub' => 'division',
};
$cr = new Config::Wrest(
	TemplateBackend => "TemplateToolkit",
	Subs => 1,
	Variables => $variables,
);

$vardata = $cr->deserialize("111 [% red %] \n \@set red BLUE \n 222 [% red %] \n");
DUMP($vardata);
ASSERT(EQUAL($vardata, {
	'111' => 'star',
	'222' => 'BLUE',
}), "variable changed and read OK");

DUMP($variables);
ASSERT(EQUAL($variables, {
	'red' => 'star',
	'sub' => 'division',
}), "original Variables unchanged");

$vardata = $cr->deserialize("111 [% red %] \n \@set red BLUE \n 222 [% red %] \n");
DUMP($vardata);
ASSERT(EQUAL($vardata, {
	'111' => 'star',
	'222' => 'BLUE',
}), "variable changed and read OK, the same as the first time");


# check the persistence of @options...
$cr = new Config::Wrest(
	TemplateBackend => "TemplateToolkit",
	Subs => 0,
	Variables => $variables,
);

$vardata = $cr->deserialize("111 [% red %] \n \@option Subs 1 \n 222 [% red %] \n");
DUMP($vardata);
ASSERT(EQUAL($vardata, {
	'111' => '[% red %]',
	'222' => 'star',
}), "option set OK");

$vardata = $cr->deserialize("111 [% red %] \n \@option Subs 1 \n 222 [% red %] \n");
DUMP($vardata);
ASSERT(EQUAL($vardata, {
	'111' => '[% red %]',
	'222' => 'star',
}), "option set OK, same as the first time");


# check the behaviour of multiple-line template expansions
$cr = new Config::Wrest(
	TemplateBackend => "TemplateToolkit",
	Subs => 1,
	Variables => {
		'xyz' => "Vapor[% red %]\n<Echo-[% green %]> \n [% distant %] radio \n ghost [% digital %] \n </>\n",
		'red' => 'tide',
		'green' => 'willow',
		'distant' => 'warning',
		'digital' => 'man',
	},
);
$vardata = $cr->deserialize("111 [% xyz %] \n 222 [% red %] \n");
DUMP($vardata);
ASSERT(EQUAL($vardata, {
	'111' => 'Vapor[% red %]',
	'222' => 'tide',
	'Echo-willow' => {
		'warning' => 'radio',
		'ghost' => 'man',
	}
}), "multiline expansion behaves correctly");


# test multilevel includes
$vardata = $cr->deserialize("boy alone\n\@include $conf_one\nfar fromhome\n");
DUMP($vardata);
ASSERT($vardata->{'includedset'}, "data from 2nd level include");
ASSERT(($vardata->{'future'}{'set'} eq 'YES'), "data from 1st level include");
