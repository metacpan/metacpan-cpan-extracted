#!/usr/local/bin/perl
use strict;

use Getopt::Std;
use Test::Assertions qw(test);
use Data::Dumper;
use Log::Trace;
use File::Basename;

#Move into the t directory if we aren't already - makes the test work from anywhere
chdir ( dirname ( $0 ) );

use vars qw($opt_t $opt_T);

# start off with this file, which is a Config::Wrest file.
use constant INFILE => "data/Writer_1.cfg";
# and write the new config here. They should be functionally the same
use constant OUTFILE => "data/Writer_1_out.cfg";

plan tests;

#This test deliberately does things which would raise warnings, and later in the
#test we look for specific warnings
$^W = 0;

#Compile the local copy of the module
unshift @INC, '../lib';
require Config::Wrest;
ASSERT($Config::Wrest::VERSION, "compiled version $Config::Wrest::VERSION");

#We allow tracing to be enabled with -t or -T for different verbosity levels
#We do this AFTER we compile our module

getopts('tT');
if($opt_t)
{
	import Log::Trace qw(print); #Local TRACE function
}
if($opt_T)
{
	deep_import Log::Trace qw(print); #Auto-replace the TRACE function in the included modules
}

# Get the canned config file into memory
my $config = new Config::Wrest( UseQuotes => 1, Escapes => 1 );
ASSERT(ref($config) eq 'Config::Wrest', 'Created cr ok');
my $data = $config->parse_file(INFILE);
undef $config;

# Write the same data back out
my $cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
ASSERT(ref($cw) eq 'Config::Wrest', 'Created cw ok');
$cw->write_file(OUTFILE, $data);
undef $cw;

# Read _that_ back in 
my $testc = new Config::Wrest( UseQuotes => 1, Escapes => 1 );
ASSERT(ref($testc) eq 'Config::Wrest', 'Created cr ok');
my $data1 = $testc->parse_file(OUTFILE);
undef $testc;

DUMP('ORIGINAL DATA', $data);
DUMP('RESTORED DATA', $data1);
ASSERT( EQUAL($data, $data1), "Input data matches output data");


# Check error handling
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
my $string;

eval { $string = $cw->parse_file(); };
my $err = $@;
chomp($err);
ASSERT($err, "No filename to read: $err");

eval { $string = $cw->write_file(); };
$err = $@;
chomp($err);
ASSERT($err, "No filename to write: $err");

eval {
	$string = $cw->serialise([qw(a b c d)]);
};
$err = $@;
chomp($err);
ASSERT($err, "Bad ref caught: $err");


eval {
	$string = $cw->serialise({
		'one' => sub { print 'here' },
	});
};
$err = $@;
chomp($err);
ASSERT($err, "Bad ref caught: $err");

eval {
	$string = $cw->serialise({
		'one' => bless({'a', 'b'}, 'CLASS'),
	});
};
$err = $@;
chomp($err);
ASSERT($err, "Bad ref caught: $err");


eval {
	$string = $cw->serialise({ 'One Thing' => 'Two' });
};
$err = $@;
chomp($err);
ASSERT($err, "Bad hash key caught: $err");

eval {
	$string = $cw->serialise({
		'OK' => 'Two',
		'Nest' => {
			'List!' => {
				qw(a b)
			},
		},
	});
};
$err = $@;
chomp($err);
ASSERT($err, "Bad hash key caught: $err");

$cw = new Config::Wrest( UseQuotes => 0 );
eval {
	$string = $cw->serialise({ 'Nest' => [ 'abc', 'def', '(apple)', ], });
};
$err = $@;
chomp($err);
ASSERT($err, "Bad value caught: $err");

eval {
	$string = $cw->serialise({ 'Nest' => [ 'abc', 'def', 'alpha beta', ], });
};
$err = $@;
chomp($err);
ASSERT($err, "Bad value caught: $err");

eval {
	$string = $cw->serialise({ 'Nest' => [ 'abc', 'def', "alpha\nbeta gamma", ], });
};
$err = $@;
chomp($err);
ASSERT($err, "Bad value caught: $err");

$cw = new Config::Wrest( UseQuotes => 1 );
$string = $cw->serialise({ 'Nest' => [ 'abc', 'def', 'alpha beta', ], });
ASSERT($string, "Bad value now OK with UseQuotes");

eval {
	$string = $cw->serialise({ 'Nest' => [ 'abc', 'def', "alpha\nbeta gamma", ], });
};
$err = $@;
chomp($err);
ASSERT($err, "Bad value still caught with quotes: $err");


# check references feature
my $nestdata1 = {
	nest => 'true',
};
my $nestdata2 = [
	'foo',
	$nestdata1,
];
my $nestdata3 = {
	qux => $nestdata2,
};

my $refdata = {
	one => 'two',
	three => $nestdata1,
	four => 'five',
	six => $nestdata1,
	seven => $nestdata2,
	eight => $nestdata3,
};


# no refs
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
$string = $cw->serialise($refdata);
TRACE(">>>$string<<<");
ASSERT(scalar($string =~ m/nest = 'true'.+nest = 'true'/s), 'No references in string - no refs at all');
ASSERT(scalar($string !~ m/\@reference/s), 'No references in string');

my $cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
my %rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, $refdata), 'parsed data structure matches' );


# assorted hash refs
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise($refdata);
TRACE(">>>$string<<<");
ASSERT(scalar($string !~ m/nest = 'true'.+nest = 'true'/s), 'References in string - shallow nesting');
ASSERT(scalar($string =~ m/\@reference six eight->qux->1/s), 'References in string');
ASSERT(scalar($string =~ m/\@reference seven eight->qux/s), 'References in string');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, $refdata), 'parsed data structure matches' );


# refs inside arrays
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise({
	foo => [ $nestdata1, ],
	bar => [ $nestdata1, ],
});
TRACE(">>>$string<<<");
ASSERT(scalar($string !~ m/nest = 'true'.+nest = 'true'/s), 'References in string - arrays');
ASSERT(scalar($string =~ m/\@reference bar->0/s), 'References in string');
ASSERT(scalar($string =~ m/nest = 'true'/s), 'References in string');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, {
	foo => [ $nestdata1, ],
	bar => [ $nestdata1, ],
}), 'parsed data structure matches' );


# refs inside arrays
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise({
	foo => [ [ $nestdata2, ] ],
	bar => [ [ $nestdata2, ] ],
});
TRACE(">>>$string<<<");
ASSERT(scalar($string !~ m/nest = 'true'.+nest = 'true'/s), 'References in string - deeper arrays');
ASSERT(scalar($string =~ m/\@reference bar->0->0/s), 'References in string');
ASSERT(scalar($string =~ m/nest = 'true'/s), 'References in string');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, {
	foo => [ [ $nestdata2, ] ],
	bar => [ [ $nestdata2, ] ],
}), 'parsed data structure matches' );


# deep hash refs
$nestdata1 = { red => 'green'};
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise({
	foo => { bar => { baz => { qux => $nestdata1 } } },
	ZFOO => { ZBAR => { ZBAZ => { ZQUX => $nestdata1 } } },
});
TRACE(">>>$string<<<");
ASSERT(scalar($string !~ m/red = 'green'.+red = 'green'/s), 'References in string - deep hashes');
ASSERT(scalar($string =~ m/\@reference qux ZFOO->ZBAR->ZBAZ->ZQUX/s), 'References in string');
ASSERT(scalar($string =~ m/red = 'green'/s), 'References in string');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, {
	foo => { bar => { baz => { qux => $nestdata1 } } },
	ZFOO => { ZBAR => { ZBAZ => { ZQUX => $nestdata1 } } },
}), 'parsed data structure matches' );


# deep hash refs
$nestdata1 = { red => 'green'};
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise({
	foo => { bar => [ { qux => $nestdata1 } ] },
	ZFOO => { ZBAR => [ { ZQUX => $nestdata1 } ] },
});
TRACE(">>>$string<<<");
ASSERT(scalar($string !~ m/red = 'green'.+red = 'green'/s), 'References in string - mixed deep refs');
ASSERT(scalar($string =~ m/\@reference qux ZFOO->ZBAR->0->ZQUX/s), 'References in string');
ASSERT(scalar($string =~ m/red = 'green'/s), 'References in string');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT( EQUAL(\%rv, {
	foo => { bar => [ { qux => $nestdata1 } ] },
	ZFOO => { ZBAR => [ { ZQUX => $nestdata1 } ] },
}), 'parsed data structure matches' );


# multiple backrefs
$nestdata1 = { 1 => 2 };
$refdata = {
	a => { d => $nestdata1 },
	b => $nestdata1,
	c => $nestdata1,
};
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise($refdata);
TRACE(">>>$string<<<");
ASSERT(scalar($string =~ m/\@reference b a->d.+\@reference c a->d/s), 'References in string - multiple backrefs to same thing');


# circular/self-referential data structure
my $cyclicarr = {
	arr => [
		'grid',
	]
};
push @{$cyclicarr->{'arr'}}, $cyclicarr->{'arr'};

my $cyclichash = {
	pedal => 'spin',
	wheel => 'turn',
};
$cyclichash->{'subassembly'} = $cyclichash;


# no refs - array - trap the error
eval {
	$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
	$string = $cw->serialise($cyclicarr);
};
chomp($@);
ASSERT($@, "Cyclic array trapped - $@");


# no refs - hash - trap the error
eval {
	$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
	$string = $cw->serialise($cyclichash);
};
chomp($@);
ASSERT($@, "Cyclic hash trapped - $@");


# with refs - array - not an error
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1 );
$string = $cw->serialise($cyclicarr);
TRACE(">>>$string<<<");
ASSERT(scalar($string =~ m/\@reference arr$/m), 'References in string - cyclic array');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT($rv{'arr'}[0] eq 'grid', "correct value from cyclic data");
ASSERT($rv{'arr'}[1][0] eq 'grid', "correct value from cyclic data");
ASSERT($rv{'arr'}[1][1][1][0] eq 'grid', "correct value from cyclic data");


# with refs - hash - not an error
$cw = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1, WriteWithReferences => 1, WriteWithHeader => 0 );
$string = $cw->serialise($cyclichash);
TRACE(">>>$string<<<");
ASSERT(scalar($string =~ m/\@reference subassembly subassembly$/m), 'References in string - cyclic hash');

$cr = new Config::Wrest( UseQuotes => 1, WriteWithEquals => 1, Escapes => 1 );
%rv = %{ $cr->deserialise($string) };
DUMP(\%rv);
ASSERT($rv{'pedal'} eq 'spin', "correct value from cyclic data");
ASSERT($rv{'subassembly'}{'pedal'} eq 'spin', "correct value from cyclic data");
ASSERT($rv{'subassembly'}{'subassembly'}{'subassembly'}{'subassembly'}{'pedal'} eq 'spin', "correct value from cyclic data");

# Test serializing into a reference
my $ser_str = $cw->serialize({ numeral => '2112', star => 'redness' });
ASSERT( $ser_str eq "numeral = '2112'\nstar = 'redness'\n", "Serialized OK" );

my $ser_ref;
$ser_str = $cw->serialize({ numeral => '2112', star => 'redness' }, \$ser_ref);
ASSERT( ! $ser_str, "When using reference, no return value" );
ASSERT( $ser_ref eq "numeral = '2112'\nstar = 'redness'\n", "Serialized OK into reference" );

eval {
	$cr->serialize({ numeral => '2112', star => 'redness' }, []);
};
chomp($@);
ASSERT($@, "Bad reference trapped: $@");


# final check on the options
$cw = new Config::Wrest( UseQuotes => 0, Escapes => 0, WriteWithEquals => 0, WriteWithHeader => 0 );
$ser_str = $cw->serialize({ 'red' => 'one two!' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(($ser_str eq "red one two!"), "serialized ok");

$cw = new Config::Wrest( UseQuotes => 1, Escapes => 0, WriteWithEquals => 0, WriteWithHeader => 0 );
$ser_str = $cw->serialize({ 'red' => 'one two!' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(($ser_str eq "red 'one two!'"), "serialized ok");

$cw = new Config::Wrest( UseQuotes => 0, Escapes => 1, WriteWithEquals => 0, WriteWithHeader => 0 );
$ser_str = $cw->serialize({ 'red' => 'one two!' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(($ser_str eq "red one%20two%21"), "serialized ok");

$cw = new Config::Wrest( UseQuotes => 0, Escapes => 0, WriteWithEquals => 1, WriteWithHeader => 0 );
$ser_str = $cw->serialize({ 'red' => 'one two!' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(($ser_str eq "red = one two!"), "serialized ok");

$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, WriteWithHeader => 0 );
$ser_str = $cw->serialize({ 'red' => 'one two!' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(($ser_str eq "red = 'one%20two%21'"), "serialized ok");

# test the various ways of writing out empty values in hashes
my $errtrap;
$SIG{'__WARN__'} = sub {
	my $e = shift();
	chomp($e);
	$errtrap = $e;
};

# this should fail w/a die
eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
};

ASSERT($@ =~ m/Config::Wrest:not writing an empty value for key 'red' \(full path 'red'\) because the AllowEmptyValues option is false/, "failed to serialize empty value (Strict)");

# this shouldn't, this should just warn
$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values (HASH)");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok");
ASSERT(length($errtrap), "trapped error: $errtrap");
$errtrap = undef;

# again, this should fail
eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
};

ASSERT ($@ =~ m/Config::Wrest:not writing an empty value for key 'red' \(full path 'red'\) because the AllowEmptyValues option is false/, "failed to serialize empty value (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok");
ASSERT(length($errtrap), "trapped error: $errtrap");
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
	$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
	chomp($ser_str);
};

ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT(scalar($ser_str =~ m/red = ''/), "serialized empty value ok");
ASSERT(!$@, "serializing empty value ok (Strict, AllowEmptyValues)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT(scalar($ser_str =~ m/red = ''/), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
	$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
	chomp($ser_str);
};

ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT(scalar($ser_str =~ m/red = ''/), "serialized empty value ok");
ASSERT(!$@, "serializing empty values ok (Strict, AllowEmptyValues)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT(scalar($ser_str =~ m/red = ''/), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
};

ASSERT(!$@, "no errors thrown (Strict)");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid (Strict)");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => undef, 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
};

ASSERT(!$@, "no errors thrown (Strict)");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid (Strict)");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => '', 'blue' => '123' });
chomp($ser_str);
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid");
ASSERT(scalar($ser_str !~ m/red/), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");
$errtrap = undef;


# test the various ways of writing out empty values in arrays
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
};

ASSERT($@ =~ m/Config::Wrest:not writing an empty value for element index 2 \(full path 'red->2'\) because the AllowEmptyValues option is false/, "failed to serialize empty value");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values (ARRAY)");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(length($errtrap), "trapped error: $errtrap");
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
};

ASSERT($@ =~ m/Config::Wrest:not writing an empty value for element index 2 \(full path 'red->2'\) because the AllowEmptyValues option is false/, "failed to serialize empty value");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(length($errtrap), "trapped error: $errtrap");
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
};

ASSERT(!$@, "no errors thrown (Strict)");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values (Strict)");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t''\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t''\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
};

ASSERT(!$@, "no errors thrown (Strict)");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values (Strict)");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t''\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, AllowEmptyValues => 1 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - allow empty values");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t''\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
};

ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid (Strict)");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok (Strict)");
ASSERT(!$@, "no errors throw (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', undef, 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");
$errtrap = undef;

eval {
	$cw = new Config::Wrest( UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
	$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
};

ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid (Strict)");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok (Strict)");
ASSERT(!$@, "no errors thrown (Strict)");

$cw = new Config::Wrest( Strict => 0, UseQuotes => 1, Escapes => 1, WriteWithEquals => 1, IgnoreInvalidLines => 1, AllowEmptyValues => 0 );
$ser_str = $cw->serialize({ 'red' => ['letters', 'to', '', 'Cleo'], 'blue' => '123' });
TRACE(">>>$ser_str<<<");
ASSERT(scalar($ser_str =~ m/blue = '123'/), "serialized ok - no empty values, ignore invalid");
ASSERT((index($ser_str, "[red]\n\t'letters'\n\t'to'\n\t'Cleo'\n[/red]\n") > 2), "serialized empty value ok");
ASSERT(!length($errtrap), "no trapped error");
$errtrap = undef;


# cleanup
unlink(OUTFILE);

