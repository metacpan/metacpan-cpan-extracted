#!/usr/bin/perl
#
# Data-Rlist.t
#
# Before `make install' is performed this script should be runnable with `make
# test'. After `make install' it should work as `perl Data-Rlist.t'
#
# $Writestamp: 2008-07-21 17:07:21 andreas$
# $Compile: perl -M'constant standalone => 1' Data-Rlist.t$

BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use warnings;
use strict;
use Env qw/HOME/;
use constant file_IO => 36;
use constant quote_and_escape => 19;
use constant here_docs => 1 + 1;
use constant beyond_the_means => 9;
use constant comments_and_error_rules => 0;

use Benchmark;
use Test::More tests => 3 + file_IO + here_docs + quote_and_escape + beyond_the_means;
use Data::Rlist;

our $t0 = new Benchmark;
our $tempfile = "$0.tmp";
our $standalone = $constant::declared{'main::standalone'};

ok(eval { require Data::Rlist; });
ok($Data::Rlist::VERSION =~ /^\d+\.\d+$/);
ok(1);							# module loaded OK

########################
# Split/parse quoted, deep-comparison.
#
if (quote_and_escape) {
	my($i);
	use Data::Rlist qw/:strings deep_compare/;

	ok(is_value($_), "is_value($_)") foreach qw/0 foo 3.14/;
	ok(quote7(undef) eq '""');
	ok(quote7(0) eq quote7("0"));		   # ...dto
	ok(quote7('"0"') eq qq'"\\"0\\""'); # ...but this is different
	ok(quote7("'0'") eq qq("\\'0\\'"));
	ok(escape7("\\ü") eq "\\\\\\374");	# \\\374
	ok(unescape7("\\\\\\374") eq "\\ü");

	ok(exists Data::Rlist::read_string('5')->{5});
	ok(exists Data::Rlist::read_string(42)->{"42"});

	sub split_and_list($) { print $i++, " '$_'\n" foreach split_quoted(shift) }
	sub parse_and_list($) { print $i++, " '$_'\n" foreach parse_quoted(shift) }

	ok($#{[split_quoted(q'"\n')]} == -1);
	ok($#{[split_quoted(q'foo"bar')]} == -1);
	ok($#{[parse_quoted(q'foo"bar')]} == -1); # defect quoted input shall return the empty list

	ok(!deep_compare([split_quoted("   foo ")], ['', 'foo', '']));
	ok(!deep_compare([split_quoted("fee fie foo")], ['fee', 'fie', 'foo']));
	ok(!deep_compare(parse_quoted('"fee fie foo"'), 1));

	ok(!Data::Rlist::deep_compare(undef, undef));
	ok( Data::Rlist::deep_compare(undef, 1));
	ok(escape7(undef) eq '' &&
	   quote7(undef) eq '""' &&
	   quote7("") eq '""' &&
	   quote7('') eq '""' &&
	   quote7(0) eq '"0"' &&	# Quoting scalar 0 is the same as...
	   quote7("0") eq '"0"' && # ...quoting "0", because quote7() converts them
                               # to strings. Therefore a scalar hosting "0" is
                               # NOT implicited quoted when compiled, because
                               # it looks like a number.
	   1);
}

if (here_docs) {
	my $hello = ReadData(\<<HELLO);
	( <<Deutsch, <<English, <<Francais, <<Castellano, <<Klingon, <<Brainf_ck )
Hallo Welt!
Deutsch
Hello World!
English
Bonjour le monde!
Francais
Olá mundo!
Castellano
~ nuqneH { ~ 'u' ~ nuqneH disp disp } name
nuqneH
Klingon
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++
..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.
Brainf_ck
HELLO
	ok($hello);
}

#########################
# Object construction and file I/O.
#

if (file_IO) {
	# Test the parser and %Rules.  In standalone-mode (i.e. not under make
	# disttest/test) we increase the number of loops to to benchmake
	# Data::Rlist::CompareData.

	#$Data::Rlist::DEBUG = 1;
	my $bench_loops = $standalone ? 20 : 1;
	my $test1file = $standalone ? 'test1.rls' : 't/test1.rls'; die unless -e $test1file;
	my $test2file = $standalone ? 'test2.rls' : 't/test2.rls'; die unless -e $test2file;
	my $test1 = ReadData $test1file; die unless $test1;
	my $test2 = ReadData $test2file; die unless $test2;

	foreach my $loop (1 .. $bench_loops) {
		foreach my $opts (undef, qw/default string squeezed outlined fast/) { # 6
			#$Data::Rlist::DEBUG = 1;
			my $thing;
			my $obj1 = new Data::Rlist(-options => $opts, -input => $test1file);
			my $obj2 = new Data::Rlist(-options => $opts, -input => $test2file);
			ok($obj1->isa('Data::Rlist'), "$obj1 has the right class");
			ok($obj2->isa('Data::Rlist'), "$obj2 has the right class");
			my $test1tmp = $obj1->read;
			my $test2tmp = $obj2->read;
			ok(ref $test1tmp, "$test1file loaded");
			ok(ref $test2tmp, "$test2file loaded");
			ok(!CompareData($test1, $test1tmp), "$test1 equal to $test1tmp ($test1file)");
			ok(!CompareData($test2, $test2tmp), "$test2 equal to $test2tmp ($test2file)");
		}
	}
}

#########################
# If we made it this far, we're ok.
#
# The rest will be "What You Ever Wanted to Know about Perl . . . But Were
# Afraid to Ask."  Like, is 42... really true? Is (undef) false?  Why is ".0"
# true?  What is the meaning of light? Is my home still there when I'm not at
# home?
#
if (beyond_the_means) {
	my @x;
	ok((@x = (undef)) && (@x = (undef, undef)));

	ok(!(@x = ()));
	ok(!"" && !'' && !.0 && !0. && !"0" && !.0);
	ok(0.==.0);					# Yet another lexical gimmick.
	ok(!.0 && ".0"); # Perl thinks this is true. Isn't this inconsistent with
                     # IEEE 754? IMHO, considering that ok(0.==.0), shouldn't
                     # it ok(!.0 && !".0")?  I'm relieved to see, however, that
                     # ok("0.").
	ok($#{[Cogito => ergo => 'sum']} == 2);
	ok(42);
	ok(QED=>);

	ok("\n\n\n" =~ /\n.+\n$/s);
}

########################
# Comments and Error rules
#

if (comments_and_error_rules) {

}


#########################

print "runtime: ", timestr(timediff(new Benchmark,$t0)), "\n\n" if $standalone;

unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
