#!/usr/local/bin/perl

# Error conditions
# $Id: Read-errors.t,v 1.9 2006/08/29 09:13:15 mattheww Exp $

use Getopt::Std;
use Test::Assertions qw(test);
use Log::Trace;
use lib qw(./lib ../lib);
use Config::Wrest;
use File::Basename;

use vars qw($opt_t $opt_T);

#Move into the t directory if we aren't already - makes the test work from anywhere
chdir ( dirname ( $0 ) );

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	deep_import Log::Trace qw(print);
}

plan tests;

my $errtrap = '';
$SIG{'__WARN__'} = sub {
	my $e = shift;
	chomp $e;
	$errtrap = $e;
};

my $cr;

# ensure an error is thrown if in strict mode
ASSERT( DIED( sub {
	$cr = new Config::Wrest ( IgnoreInvalidLines => 0 );
	$cr->parse_file("data/Reader_bad_config.cfg");
} ), "parsing threw an error" );

# ensure warnings happen
$cr = new Config::Wrest( Strict => 0, IgnoreInvalidLines => 0 );
my $rv = $cr->parse_file("data/Reader_bad_config.cfg");
DUMP($rv);
ASSERT($rv, 'file was parsed despite errors');
ASSERT($rv->{'Evil'} eq '../up/a/bit', 'dot dot value OK');
ASSERT((@{ $rv->{'list'} } == 3), 'only three list items');

# should have made an error
ASSERT( $errtrap, 'error was logged' );

# nesting error - die
ASSERT( DIED(sub {
	$cr = new Config::Wrest( Strict => 1, IgnoreInvalidLines => 0 );
	$cr->parse_file("data/Reader_badnesting.cfg");
} ), 'fatal nesting error');

# stack underflow - die
ASSERT( DIED(sub {
	$cr = new Config::Wrest( Strict => 1, IgnoreInvalidLines => 0 );
	$cr->parse_file("data/Reader_underflow.cfg");
} ), 'fatal stack underflow' );

# dos line breaks should actually work - but let's check...
ASSERT( $cr = new Config::Wrest( Strict => 0, IgnoreInvalidLines => 0 ), 'new object with DOS line endings' );
my $vardata = $cr->parse_file("data/Reader_dosfile.cfg");
ASSERT( $vardata->{'foo'} eq 'bar', 'value correct');
ASSERT( $vardata->{'top'}{'middle'} eq 'middle', 'value correct');
ASSERT( $vardata->{'charm'} eq 'beauty', 'value correct');

# unclosed tags - warning
ASSERT( $cr = new Config::Wrest( Strict => 0, IgnoreInvalidLines => 0, IgnoreUnclosedTags => 1 ), 'warning for unclosed tags' );
$cr->parse_file("data/Reader_unclosed.cfg");
# should have made an error
ASSERT( $errtrap, 'error logged' );

# refresh error - die
$cr = new Config::Wrest;
$vardata = $cr->deserialize(q{
One Two
Three Four
});
ASSERT(keys(%$vardata)==2, 'object parsed string OK');

ASSERT( DIED( sub {
	my $cr = new Config::Wrest();
	$cr->deserialize("<foo>\n[/]\n");
} ), "Trapped error" );

ASSERT( DIED( sub {
	my $cr = new Config::Wrest();
	$cr->deserialize("[foo]\n[foo]\n[/]\n</>\n");
} ), "Trapper error" );
