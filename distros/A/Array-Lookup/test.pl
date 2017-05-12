#!/usr/bin/perl
#
# test program for Array::Lookup.pm
#
#    Copyright (C) 1996-2014  Alan K. Stebbens <aks@stebbens.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

use Array::Lookup;

$testout  = 'test.out';		# where this output goes
$testref  = "$testout.ref";
$testdiff = "$testout.diff";

unlink $testout;

open(savSTDOUT, ">&STDOUT");
open(savSTDERR, ">&STDERR");

open(STDOUT,">test.stdout"); open(STDERR,">test.stderr");
select(STDOUT);

&the_test;			# run the test

close STDOUT; close STDERR;

# Copy stdout & stderr to the test.out file
open(TESTOUT,">$testout");
select(TESTOUT);
print "*** STDOUT ***\n";
open(OUT,"<test.stdout"); while (<OUT>) { print; } close OUT;
print "*** STDERR ***\n";
open(ERR,"<test.stderr"); while (<ERR>) { print; } close ERR;
close TESTOUT;
unlink ('test.stdout', 'test.stderr');

open(STDOUT, ">&savSTDOUT");
open(STDERR, ">&savSTDERR");
select(STDOUT); $|=1;

if (! -f $testref) {			# any existing reference?
    system("cp $testout $testref");	# no, copy
}

system("diff -u $testref $testout >$testdiff");

$exit = 0;
if ($?>>8) {
    print "Uh-oh! There are differences; see \"$testdiff\".\n";
    $exit = 1;
} else {
    print "Yea! No differences.\n";
    unlink $testdiff;
}

exit $exit;

#    test $arg1, $arg2, $arg3 ..
#
# Run test and then print the results

sub test {
    my $key = shift;
    my $keytab = shift;
    my $notfound = shift;
    my $ambig = shift;
    printf "Search for '%s' on \%s", $key, $keytab;
    if ($notfound) {
	printf ", notfound = '%s'", $notfound;
	$notfound = eval ('\\&'.$notfound);
    }
    if ($ambig) {
	printf ", ambig = '%s'", $ambig;
	$ambig = eval ('\\&'.$ambig);
    }
    printf "\n";
    my $result = lookup $key, (eval '\\'.$keytab), $notfound, $ambig;
    $result = '<undef>' if !defined($result);
    printf "Result = '%s'\n", $result;
}

sub showarray;

sub errsub {
    my ($key, $kt, $ambig) = @_;
    printf "Key '%s' ",$key;
    my $ar;
    if (ref($ambig) eq 'ARRAY') {
	printf "is ambiguous\n";
	printf "Choose from: ";
	showarray $ambig;
    } else {
	printf "not found\n";
    }
    printf "Choices were: ";
    showarray $kt;
}

sub showarray {
    my $ar = shift;
    if (ref($ar) eq 'ARRAY') {
	printf join(', ', sort(@$ar));
    } elsif (ref($ar) eq 'HASH') {
	printf join(', ', sort(keys %$ar));
    } else {
	printf "%s", $ar;
    }
    printf "\n";
}

sub the_test {

    # Make an array of commands
    @commands = sort qw( use server save wait write get put list set quit exit help );

    # Make a HASH of the same commands
    @commands{@commands} = @commands;


    test 'u',	'@commands';
    test 'us',	'@commands';
    test 'use',	'@commands';
    test 'user',	'@commands';

    test 'u',	'%commands';
    test 'us',	'%commands';
    test 'use',	'%commands';
    test 'user',	'%commands';

    test 's',	'@commands';
    test 'se',	'@commands';
    test 'ser',	'@commands';
    test 'set',	'@commands';
    test 'serv',	'@commands';
    test 'serve',	'@commands';
    test 'server',	'@commands';
    test 'servers',	'@commands';

    test 's',	'%commands';
    test 'se',	'%commands';
    test 'ser',	'%commands';
    test 'set',	'%commands';
    test 'serv',	'%commands';
    test 'serve',	'%commands';
    test 'server',	'%commands';
    test 'servers',	'%commands';

    foreach $word (@commands) {
	for ($i = 1; $i <= length($word); $i++) {
	    $testkey = substr($word,0,$i);
	    test $testkey, '@commands';
	    test $testkey, '%commands';
	    test $testkey, '@commands', 'errsub';
	    test $testkey, '@commands', 'errsub', 'errsub';
	    test $testkey, '%commands', 'errsub';
	    test $testkey, '%commands', 'errsub', 'errsub';
	}
    }

    # Build a big array of words
    @words = split(' ',`cat GNU-LICENSE`);
    @words = grep !/http:/, @words;   # remove possibly long http URL "words"
    foreach ( @words) { s/\W+$//; s/^\W+//; }
    @words{@words} = @words;
    @words = sort keys %words;
    undef %words;

    $count = 0;
    foreach $word (@words) {
	$count++ if (lookup $word, \@words);
    }
    printf "Found %d words in an array of %d words\n", $count, ($#words + 1);

}
