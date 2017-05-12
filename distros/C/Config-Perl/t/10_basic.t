#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

use Test::More;
use Test::Fatal 'exception';
use File::Temp 'tempfile';

use Config::Perl;

# ### Basics & Structure ###

test_ppconf q{ $foo="bar"; }, { '$foo'=>"bar" }, 'basic test';
test_ppconf q{ $foo="bar" }, { '$foo'=>"bar" }, 'no semicolon';
test_ppconf q{ our $foo="bar"; }, { '$foo'=>"bar" }, '"our"';
test_ppconf q{ our $foo=123; }, { '$foo'=>123 }, 'number';
test_ppconf q{ my $foo=123; }, { '$foo'=>123 }, '"my" in outermost block',
	{del_syms=>['$foo']};
test_ppconf q{}, {}, 'empty doc';
test_ppconf q{ "foo";; }, { '_'=>["foo"] }, 'two semicolons';

test_ppconf q{ "foo" }, { _=>["foo"] }, 'plain value';
test_ppconf q{ ('foo','bar') }, { _=>["foo","bar"] }, 'plain list';
test_ppconf q{ ["foo","bar"] }, { _=>[["foo","bar"]] }, 'plain arrayref';
test_ppconf q{ {foo=>"bar"} }, { _=>[{foo=>"bar"}] }, 'plain hashref';
test_ppconf q{ $foo=123; $bar=456; }, { '$foo'=>123, '$bar'=>456 }, 'two vars';
test_ppconf q{ $VAR1 = { 'foo' => 'bar' }; }, { '$VAR1'=>{foo=>"bar"} }, 'Data::Dumper hashref';
test_ppconf q{ $VAR1 = 'quz'; $VAR2 = 'baz'; }, { '$VAR1'=>"quz", '$VAR2'=>"baz" }, 'Data::Dumper list';

ok exception {
	Config::Perl->new->parse_or_die(
		\q{ our @x = qw/a b/, our @y = qw/c d/ });
}, 'accidental comma fails';

test_ppconf q{ LBL: "foo" }, { _=>["foo"] }, 'plain value w/ label';
test_ppconf q{ LBL: $foo = "bar"; }, { '$foo'=>"bar" }, 'assignment w/ label';
test_ppconf q{ LBL: our $foo="bar"; }, { '$foo'=>"bar" }, 'decl w/ label';
test_ppconf q{ LBL: do { "foo" } }, { _=>["foo"] }, 'do block w/ label';

test_ppconf q{ our $test = ("Hello","World"); },
	{ '$test' => 'World' }, 'list in scalar';
test_ppconf q{ our $test = ("Hello","World",()); },
	{ '$test' => undef }, 'list to scalar w/ empty list';
test_ppconf q{ our $test = qw/ foo bar quz /; },
	{ '$test' => 'quz' }, 'qw in scalar';

# parse from file
my ($fh, $fn) = tempfile(UNLINK=>1);
print $fh <<'END';
$foo = "bar";
$quz = 123;
END
close $fh;
my $cp = Config::Perl->new;
is_deeply $cp->parse_or_undef($fn),
	{ '$foo'=>"bar", '$quz'=>123 }, 'parse file';

# ### Interpolation ###

test_ppconf q{ our $foo='$bar'; }, { '$foo'=>'$bar' }, 'non-interpolated';
test_ppconf q{ our $foo= -bar; }, { '$foo'=>-bar }, 'dashed bareword';
test_ppconf q{ our $foo="bar"; our $quz="baz$foo"; },
	{ '$foo'=>"bar", '$quz'=>"bazbar" }, 'interpolation';

test_ppconf q{ our $foo="bar"; our $quz="baz$foo$foo"; },
	{ '$foo'=>"bar", '$quz'=>"bazbarbar" }, 'multi interp';
test_ppconf q{ our $foo="bar"; our $quz="${foo}baz"; },
	{ '$foo'=>"bar", '$quz'=>"barbaz" }, 'interp in braces';
test_ppconf q{ our $foo=q{ { $bar } }; }, { '$foo'=>' { $bar } ' }, 'q';
test_ppconf q{ our $foo=qq{ { bar } }; }, { '$foo'=>' { bar } ' }, 'qq';
test_ppconf q{ our $foo="bar"; our $quz=qq{ { <$foo> } }; },
	{ '$foo'=>'bar', '$quz'=>' { <bar> } ' }, 'qq interpolated';
ok exception {
	Config::Perl->new->parse_or_die(
		\q{ our $foo="bar"; our $quz="baz$foo$"; });
}, 'trailing sigil fails';
test_ppconf q{ our $foo="bar"; our $quz="baz$foo@"; },
	{ '$foo'=>"bar", '$quz'=>"bazbar@" }, 'interp trailing at';

test_ppconf q{ our $foo="bar"; our $quz="baz\\$foo"; }, # in: \$
	{ '$foo'=>"bar", '$quz'=>"baz\$foo" }, 'escaped interp 1'; # out: $
test_ppconf q{ our $foo="bar"; our $quz="baz\\\\$foo"; }, # in: 1x \\
	{ '$foo'=>"bar", '$quz'=>"baz\\bar" }, 'escaped interp 2'; # out: 1x \
test_ppconf q{ our $foo="bar"; our $quz="baz\\\\\\$foo"; }, # in: 1x \\ + \$
	{ '$foo'=>"bar", '$quz'=>"baz\\\$foo" }, 'escaped interp 3'; # out: 1x \ + $
test_ppconf q{ our $foo="bar"; our $quz="baz\\\\\\\\$foo"; }, # in: 2x \\
	{ '$foo'=>"bar", '$quz'=>"baz\\\\bar" }, 'escaped interp 4'; # out: 2x \

test_ppconf q{ our $foo="bar\n"; }, { '$foo'=>"bar\n" }, 'interp newline';
test_ppconf q{ our $foo="bar\r\n"; }, { '$foo'=>"bar\r\n" }, 'interp linefeed';
test_ppconf q{ our $foo="\tbar\n\tquz"; }, { '$foo'=>"\tbar\n\tquz" }, 'interp tab';
test_ppconf qq{ our \$foo="bar\n\tquz"; }, { '$foo'=>"bar\n\tquz" }, 'embedded newline & tab';

test_ppconf q{ our $foo="\0534\x4F0\1753"; }, { '$foo'=>"+4O0}3" }, 'backsl oct & hex';
#TODO Later: more tests for backslash escapes

# ### Assignments ###

test_ppconf q{ our $foo=123; our $bar=456; }, { '$foo'=>123, '$bar'=>456 }, 'two dedcls';
test_ppconf q{ our $foo=123; our $bar=$foo; }, { '$foo'=>123, '$bar'=>123 }, 'assign one var to other';

test_ppconf q{ our ($foo,$bar) = (123,456); }, { '$foo'=>123, '$bar'=>456 }, 'list assign decl';
test_ppconf q{ our (undef,$bar) = (123,456); }, { '$bar'=>456 }, 'list assign decl w/ undef';
test_ppconf q{ ($foo,$bar) = (123,456); }, { '$foo'=>123, '$bar'=>456 }, 'list assign';
test_ppconf q{ our ($foo=>$bar) = (123,456); }, { '$foo'=>123, '$bar'=>456 }, 'list assign decl w fat comma';
ok exception {
	diag(explain( Config::Perl->new->parse_or_die(
		\q{ our (undef=>$bar) = (123,456); }) ));
}, 'assign to "undef" fails (fat comma)';

# ### Arrays & Hashes ###

test_ppconf q{ our %hash = ( foo=>123, bar=>456 ); },
	{ '%hash' => { foo=>123, bar=>456 } }, 'hash';
test_ppconf q{ our %hh = ( -quz=>"beep", baz=>-meep ); },
	{ '%hh' => { -quz=>"beep", baz=>-meep } }, 'hash with dashed barewords';
test_ppconf q{ $foo{bar} = 'quz' }, { '%foo' => {bar=>'quz'} }, 'hash elem';

test_ppconf q{ our @ary = ("Hello","World"); },
	{ '@ary' => ["Hello","World"] }, 'array';
test_ppconf q{ our @ary = qw/ foo bar quz /; },
	{ '@ary' => [qw/ foo bar quz /] }, 'qw';
test_ppconf q{ our @ary = qw{ foo bar quz }; },
	{ '@ary' => [qw{ foo bar quz }] }, 'qw w/special chars 1';
test_ppconf q{ our @ary = qw# foo bar quz #; },
	{ '@ary' => [qw# foo bar quz #] }, 'qw w/special chars 1';
test_ppconf q{ $ary[2] = "Beep"; },
	{ '@ary' => [undef,undef,"Beep"] }, 'subscript ary';
test_ppconf q{ ($ary[3],$ary[1]) = ("Bar","Foo"); },
	{ '@ary' => [undef,"Foo",undef,"Bar"] }, 'list assign with subscript';
test_ppconf q{ our @ary = (qw/a b c/); our $foo = $ary[2]; },
	{ '@ary'=>['a','b','c'], '$foo'=>'c' }, 'subscript on rhs';
test_ppconf q{ our (@ary) = qw/a b c/; $ary[0] = $ary[1]; },
	{ '@ary'=>['b','b','c'] }, 'lhs & rhs w/ subscript';
test_ppconf q{ our (@ary) = qw/a b c/; ($foo,$ary[0]) = ($ary[1],$ary[2]); },
	{ '@ary'=>['c','b','c'], '$foo'=>'b' }, 'lhs & rhs list with subscript';
test_ppconf q{ our $x = 2; our @ary = qw/r j k/; $ary[$x] },
	{ '@ary'=>['r','j','k'], '$x'=>2, _=>['k'] }, 'array subscript variable';
test_ppconf q{ our %h = (bf=>-xx); our $z = 'b'; $h{"${z}f"} },
	{ '%h'=>{bf=>'-xx'}, '$z'=>'b', _=>['-xx'] }, 'hash subscript interp string';

ok exception {
	Config::Perl->new->parse_or_die(\q{ $foo{bar()} = "quz" });
	}, 'too complex hash key 1';
ok exception {
	Config::Perl->new->parse_or_die(\q{ $foo{+bar} = "quz" });
	}, 'too complex hash key 2';
ok exception {
	Config::Perl->new->parse_or_die(\q{ $foo{&bar} = "quz" });
	}, 'too complex hash key 3';

test_ppconf q{ @x=qw/a b c/; $y=@x }, { '@x'=>['a','b','c'], '$y'=>3 }, 'assign array to scalar';
my %thash1 = qw/a b c d/;
test_ppconf q{ %x=qw/a b c d/; $y=%x }, { '%x'=>\%thash1, '$y'=>scalar %thash1 }, 'assign hash to scalar';

test_ppconf q{ @x=qw/a b/; @y=@x }, { '@x'=>['a','b'], '@y'=>['a','b'] }, 'assign array to array';
test_ppconf q{ @y=('x',('d','e'),'y'); },
	{ '@y'=>['x','d','e','y'] }, 'array assign, list in rhs list';
test_ppconf q{ @y=('x',(),'y'); },
	{ '@y'=>['x','y'] }, 'array assign, empty list in rhs list';
test_ppconf q{ @y=((),'x',('r','u'),(),'y',()); },
	{ '@y'=>['x','r','u','y'] }, 'array assign, empty lists in rhs list';
test_ppconf q{ @x=qw/a b/; @y=('x',@x,'y'); },
	{ '@x'=>['a','b'], '@y'=>['x','a','b','y'] }, 'array assign, array in rhs list';
test_ppconf q{ %x=(a=>"b"); @y=('x',%x,'y'); },
	{ '%x'=>{a=>"b"}, '@y'=>['x','a','b','y'] }, 'array assign, hash in rhs list';
test_ppconf q{ @x=qw/a b/; %y=(@x,d=>'e'); },
	{ '@x'=>['a','b'], '%y'=>{a=>'b',d=>'e'} }, 'hash assign, array in rhs list';
test_ppconf q{ %x=qw/a b/; %y=(a=>'x',c=>'d',%x) },
	{ '%x'=>{a=>'b'}, '%y'=>{a=>'b',c=>'d'} },  'hash assign, hash in rhs list (override)';
test_ppconf q{ %x=qw/a b/; %y=(c=>'d',%x,a=>'x') },
	{ '%x'=>{a=>'b'}, '%y'=>{a=>'x',c=>'d'} },  'hash assign, hash in rhs list (overridden)';

test_ppconf q{ @foo = ("a","b","c"); @foo },
	{ '@foo' => ["a","b","c"], _=>["a","b","c"] }, 'array as last elem';

test_ppconf q{ @y=('x','y','z'); $x=('a',@y); },
	{ '@y'=>['x','y','z'], '$x'=>3 }, 'list assign, scalar ctx passthru';
test_ppconf q{ $x=(); @y=(); %z=(); $a=[]; $b={}; },
	{ '$x'=>undef, '@y'=>[], '%z'=>{}, '$a'=>[], '$b'=>{} }, 'empty lists assign';

test_ppconf q{ @x=qw/a/; @x=qw/b c/; }, { '@x'=>['b','c'] }, 'assign to existing array';
test_ppconf q{ @x=qw/a b/; @x=qw/c/; }, { '@x'=>['c'] }, 'assign to existing array smaller';

test_ppconf q{ %x=qw/a b/; %x=qw/c d e f/; }, { '%x'=>{c=>'d',e=>'f'} }, 'assign to existing hash';
test_ppconf q{ %x=qw/a b c d/; %x=qw/e f/; }, { '%x'=>{e=>'f'} }, 'assign to existing hash smaller';

# ### References & Structures ###

test_ppconf q{ our $aref = ['foo',555,'bar']; },
	{ '$aref'=>['foo',555,'bar'] }, 'arrayref';
test_ppconf q{ our $href = {foo=>123, bar=>456}; },
	{ '$href'=>{foo=>123, bar=>456} }, 'hashref';

test_ppconf <<'ENDX'
    our $s = {
	   foo => [ {x=>1,y=>2}, "blah" ],
	   bar => { quz=>[7,8,9], baz=>"bleep!" },
	};
ENDX
	, { '$s' => { 
	   foo => [ {x=>1,y=>2}, "blah" ],
	   bar => { quz=>[7,8,9], baz=>"bleep!" },
	} }, 'complex structure';

# ### Blocks ###

test_ppconf q{ do { "abc" } }, { '_' =>[ 'abc' ] }, 'do block';
test_ppconf q{ our $foo = do { "def" } }, { '$foo' => 'def' }, 'simple do block';
test_ppconf q{ our @foo = ("a", do { 345 }, "c") }, { '@foo' => ["a",345,"c"] },
	'do block in list';
test_ppconf q{ do {} }, { }, 'empty do block';

done_testing;

