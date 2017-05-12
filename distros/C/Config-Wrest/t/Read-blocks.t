#!/usr/local/bin/perl

#
# <hash> and [list] block functionality test
# $Id: Read-blocks.t,v 1.2 2006/06/23 09:07:17 mattheww Exp $

use strict;
use Getopt::Std;
use lib("./lib","../lib");
use Config::Wrest;
use Test::Assertions('test');
use Log::Trace;

use vars qw($opt_t $opt_T);

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	import Log::Trace qw(print), { Deep => 1 };
}

#So if can find config files even when run from make
use Cwd;
chdir 't' if -d 't';
my $root=cwd;

plan tests => 14;
my $cr;

ASSERT( $cr = new Config::Wrest(), 'new object' );
my $vardata = $cr->parse_file("$root/data/Reader_1.cfg");
DUMP('Variables', $vardata);

# Hash-like blocks

# values in one block deep - tests 2 - 4
ASSERT( ref( $vardata->{"alpha"} ) eq 'HASH', 'correct reference type');
ASSERT( $vardata->{"alpha"}->{'Tony'} eq 'Robinson', 'hash dereference');
ASSERT( $cr->_var("alpha->Tony", $vardata) eq 'Robinson', 'hash infix dereference');

# values in 2 blocks deep - test 5 & 6
ASSERT( $vardata->{"alpha"}->{'beta'}->{'Edmund'} eq 'Blackadder', 'deep hash element');
ASSERT( $cr->_var("alpha->beta->Edmund", $vardata) eq 'Blackadder', 'deep hash element, infix notation');

my $h = $cr->_var("alpha->gamma", $vardata);
ASSERT( $h->{'Rowan'} eq 'Atkinson', 'indirect dereferencing' );

# ridiculously deep nesting - tests 8&9
ASSERT( $cr->_var("alpha->gamma->foo->bar->baz->quux->it->key", $vardata) eq 'val', '8 level deep infix pointers' );
ASSERT( $vardata->{"alpha"}->{'gamma'}->{'foo'}->{'bar'}->{'baz'}->{'quux'}->{'it'}->{'key'} eq 'val', '8 level deep perl-side dereference' );

# List-like blocks - tests 10..14
ASSERT( $cr = new Config::Wrest( UseQuotes => 1, Escapes => 1 ), 'new object' );
$vardata = $cr->parse_file("$root/data/Reader_1.cfg");
DUMP('Variables', $vardata);

# work with private method
$cr->{'vars'} = $vardata;
ASSERT( $cr->_var("alpha->nest->3->2->eat->food", $vardata) eq 'good', 'array dereference' );
ASSERT( $vardata->{"alpha"}->{nest}->[3]->[2]->{eat}->{food} eq 'good', 'array dereference' );

my $a = $cr->_var("alpha->nest->3", $vardata);
ASSERT( $a->[0] eq 'uk', 'indirect list dereference' );
ASSERT( $a->[3] eq 'this is escaped"', $a->[3] );
