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

use Data::Dumper ();

# Data::Undump::PPI used to support Data::Dump, but since that support was
# only partial, I've disabled it completely for now to avoid confusion.
# Also, since the output of Data::Dumper with the Terse option is often
# indistinguishable from Data::Dump, this means Terse is currently not supported.
our $HAVE_DATA_DUMP;
$HAVE_DATA_DUMP = 0;
#BEGIN { $HAVE_DATA_DUMP = eval q{ use Data::Dump 'pp'; 1 } };  ## no critic (ProhibitStringyEval)
#diag  $HAVE_DATA_DUMP ? "Note: have Data::Dump" : "DON'T have suggested module Data::Dump";

BEGIN {
	use_ok 'Data::Undump::PPI';
}

# each element of @TESTS is a hashref:
# { pp => <whether this test is expected to work with Data::Dump>,
#   data => [<test data>] }
my @TESTS = (
	{ pp=>1, data=>[ "Hello" ] },
	{ pp=>1, data=>[ "Hello", "World" ] },
	{ pp=>0, data=>[ 1..20 ] }, #TODO Later: Support range operator (Data::Dump generates code with it)
	{ pp=>1, data=>[ map {$_*3} 1..20 ] }, # Data::Dump won't infer the range here
	{ pp=>1, data=>[ {foo=>"bar",quz=>"baz"} ] },
	{ pp=>1, data=>[ [qw/abc def/] ] },
	{ pp=>1, data=>[ {foo=>"bar"}, ["quz","baz"], "blah" ] },
	{ pp=>1, data=>[ "A\x00B", "C\x11D", "E\x7FF" ] },
	{ pp=>1, data=>[ { foo=>[-abc,{def=>123},["hello",1,-7e8,9.8001]],
	  bar=>{deep=>{hash=>{refs=>567},blah=>[444]}} } ] },
	{ pp=>0, data=>[ do { my $x={foo=>"bar"}; ($x,$x,[$x,$x]) } ] },
	#TODO Later: more tests for self-referential data structures
);

sub testundump ($$;$) {  ## no critic (ProhibitSubroutinePrototypes)
	my ($string,$data,$name) = @_;
	$name ||= "Undump";
	my @parsed = eval { Undump($string) };
	my $e = $@ ? "\$\@=$@" : "(no \$\@)\n";
	is_deeply \@parsed, $data, $name
		or diag explain "data=",$data, "str=$string\n", $e, "parsed=",\@parsed;
	return;
}

for my $test (@TESTS) {
	my $dd = Data::Dumper->new($$test{data});
	# Purity should always be turned on
	$dd->Purity(1)->Useqq(0)->Deepcopy(0)->Terse(0);
	# Basic test
	testundump($dd->Dump,$$test{data},"Undump Data::Dumper");
	$dd->Reset;
	# Useqq
	$dd->Useqq(1);
	testundump($dd->Dump,$$test{data},"Undump Data::Dumper w/ Useqq");
	$dd->Reset->Useqq(0);
	# Deepcopy
	$dd->Deepcopy(1);
	testundump($dd->Dump,$$test{data},"Undump Data::Dumper w/ Deepcopy");
	$dd->Reset->Deepcopy(0);
	# String ends on true value
	testundump($dd->Dump."; 1;",$$test{data},"Undump Data::Dumper w/ true 1");
	$dd->Reset;
	# sometimes people use a string instead of "1;" as a true value
	testundump($dd->Dump."; \"true\";",$$test{data},"Undump Data::Dumper w/ true 2");
	$dd->Reset;
	# NOTE See notes on Data::Dump on why I've disabled support for Terse for now
	if (0 && @{$$test{data}}==1) { # Terse only produces valid Perl with one value
		$dd->Terse(1);
		testundump($dd->Dump,$$test{data},"Undump Data::Dumper w/ Terse");
		$dd->Reset->Terse(0);
	}
	if ($HAVE_DATA_DUMP && $$test{pp}) {
		testundump(pp(@{$$test{data}}),$$test{data},"Undump Data::Dump");
	}
}

# ### more complex test of Data::Dumper self-referential data structures ###
my $STRUCT = {
	foo => [ {x=>1,y=>2}, "blah" ],
	bar => { quz=>[7,8,9], baz=>"bleep!" },
	quz => [ { a=>[qw/b c d/,{x=>4},7], b=>{t=>["u","v","x"]} },
		[3,4,5,[6,7,8]], "h" ], };
$STRUCT->{refs} = [
	$STRUCT->{foo},
	$STRUCT->{foo}->[0],
	$STRUCT->{bar}->{quz},
	$STRUCT->{quz}->[0]->{a}->[3],
	$STRUCT->{quz}->[0]->{b}->{t},
	$STRUCT->{quz}->[1]->[3],
	];
my $str = Data::Dumper->new([$STRUCT])
	->Purity(1)->Useqq(0)->Deepcopy(0)->Terse(0)->Dump;
$str .= <<'ENDMORE'; # a few more refs to individual values with specific formats
$x = $VAR1->{foo}->[1];
$y = $VAR1->{quz}->[0]->{b}->{t}->[1];
$z = $VAR1->{quz}->[1][3][2];
ENDMORE
test_ppconf $str, {'$VAR1'=>$STRUCT, '$x'=>"blah", '$y'=>"v", '$z'=>8},
	'Data::Dumper complex self-ref. structure';
# ###

done_testing;

