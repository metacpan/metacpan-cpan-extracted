#!/usr/local/bin/perl
use strict;

use lib qw(./lib ../lib);
use Config::Wrest;

use Getopt::Std;
use Test::Assertions qw(test);
use Data::Dumper;
use Log::Trace;

use vars qw($opt_t $opt_T);

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

my $conf = 'data/Reader_directives3.cfg';

# note - all options are OFF
ASSERT( DIED(sub {
	my $cr = new Config::Wrest();
	$cr->parse_file($conf);
} ), 'recursive include is trapped');

ASSERT( DIED(sub {
	my $cr = new Config::Wrest();
	$cr->deserialize('
@include nonexistent
');
} ), 'missing file trapped');

SCOPE: {
	my $s = '';
	local $SIG{__WARN__} = sub { $s .= shift; };
	my $cr = new Config::Wrest( Strict => 0 );
	ASSERT($cr, 'created object');
	$cr->deserialize('
	@made up directive
	');
	TRACE("warning is <$s>");
	ASSERT(scalar($s =~ m/could not understand directive/), "warning generated");
}

{
	my $s = '';
	my $cr = new Config::Wrest();
	ASSERT($cr, 'created object');
eval {
	$cr->deserialize('
		@made up directive
	');
};
	ASSERT(scalar($@ =~ m/could not understand directive/), "error generated");
}

eval {
	my $cr = new Config::Wrest();
	$cr->deserialize('<foo>
</>
@Reference foo
');
};
chomp($@);
ASSERT($@, "Trapped error (Strict) $@");

eval {
	my $cr = new Config::Wrest( Strict => 0 );
	$cr->deserialize('<foo>
</>
@Reference foo
');
};
chomp($@);
ASSERT($@, "Trapped error $@");

# test to make sure that a nonexistant variable fails
eval {
	my $cr = new Config::Wrest ( DieOnNonExistantVars => 1 );
	$cr->_var("This->Variable->Does->Not->Exist", {});
};
chomp($@);
ASSERT($@, "Trapper error : $@");
