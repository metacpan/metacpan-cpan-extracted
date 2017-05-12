#!/usr/local/bin/perl

# Can we read lists of values
# $Id: Read-lists.t,v 1.2 2006/06/23 09:07:17 mattheww Exp $

use strict;
use Getopt::Std;
use lib qw(./lib ../lib);
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
if (-d 't') { chdir 't'; }

Test::Assertions::plan tests => 10;
my $cr;

ASSERT( $cr = new Config::Wrest( UseQuotes => 1, Escapes => 1 ), 'new object' );
my $vardata = $cr->parse_file('data/Reader_short.cfg');
DUMP('Variables', $vardata);

# hook into a private method for testing:
ASSERT( $cr->_var('Params->a->Type', $vardata) eq 'List', 'infix has dereference' );
ASSERT( $cr->_var('Params->a->List->1', $vardata) eq 'no', 'infix array dereference' );
ASSERT( $cr->_var('Params->b->List->2', $vardata) eq '3', 'infix array dereference' );
ASSERT( $cr->_var('Params->c->List->0', $vardata) eq 'a', 'infix array dereference' );


ASSERT( $cr = new Config::Wrest('data/Reader_short.cfg', {UseQuotes => 1, Escapes => 1}), 'new object' );
$vardata = $cr->parse_file('data/Reader_short.cfg');
DUMP('Variables', $vardata);

ASSERT( $vardata->{'Params'}->{a}->{Type} eq 'List', 'multiple dereference leading to hash element' );
ASSERT( $vardata->{'Params'}->{a}->{List}->[1] eq 'no', 'multiple dereference leading to array element' );
ASSERT( $vardata->{'Params'}->{b}->{List}->[2] eq '3', 'multiple dereference leading to array element' );
ASSERT( $vardata->{'Params'}->{c}->{List}->[0] eq 'a', 'multiple dereference leading to array element' );
