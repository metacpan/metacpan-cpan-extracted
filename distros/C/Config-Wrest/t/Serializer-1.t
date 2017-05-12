#!/usr/local/bin/perl
use strict;

use Getopt::Std;
use Test::Assertions qw(test);
use Data::Dumper;
use Log::Trace;

use vars qw($opt_t $opt_T);

BEGIN {
	eval "use Data::Serializer;";
	if ($@) {
		print "1..1\n";
		print "ok 1 (Skipping ALL tests - Data::Serializer NOT installed)\n";
		exit(0);
	}
}
plan tests;

#Move into the t directory if we aren't already - makes the test work from anywhere
chdir($1) if($0 =~ /(.*)\/(.*)/);

#Compile the local copy of the module
unshift @INC, '../lib';
require Data::Serializer::Config::Wrest;
ASSERT($Data::Serializer::Config::Wrest::VERSION, "compiled version $Data::Serializer::Config::Wrest::VERSION");

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	import Log::Trace qw(print), { Deep => 1 };
}


my $ser = Data::Serializer->new(
	serializer => 'Config::Wrest',
);
DUMP($ser);

my $struct = {a => [1,2,3],b => 5};

my $serialized = $ser->serialize($struct);
DUMP("SERIALIZED", $serialized);

my $deserialized = $ser->deserialize($serialized);
DUMP("DESERIALIZED", $deserialized);

ASSERT(EQUAL($struct, $deserialized), "Round trip OK");


$serialized = $ser->raw_serialize($struct);
DUMP("SERIALIZED", $serialized);
ASSERT(scalar($serialized =~ m/b '5'/), "Serialized with defaults");

$deserialized = $ser->raw_deserialize($serialized);
DUMP("DESERIALIZED", $deserialized);

ASSERT(EQUAL($struct, $deserialized), "Round trip OK, raw");


$ser = Data::Serializer->new(
	serializer => 'Config::Wrest',
	options => {
		Escapes => 1,
		UseQuotes => 1,
		WriteWithEquals => 1,
	}
);
DUMP($ser);
$serialized = $ser->raw_serialize($struct);
DUMP("SERIALIZED", $serialized);
ASSERT(scalar($serialized =~ m/b = '5'/), "Serialized with non-default values");

$serialized = $ser->raw_serialize({ foo => "Davey McKee!" });
DUMP("SERIALIZED", $serialized);
ASSERT(scalar($serialized =~ m/foo = 'Davey%20McKee%21'/), "Serialized with non-default values");


### Error conditions
eval {
	$serialized = $ser->serialize(['bad']);
};
chomp($@);
ASSERT($@, "Error trapped: $@");

my $x = {};
$x->{'ref'} = $x;
eval {
	local $^W = 0;
	$serialized = $ser->serialize($x);
};
chomp($@);
ASSERT($@, "Error trapped: $@");

eval {
	$deserialized = $ser->raw_deserialize('@include doesnotexistthisfileisnothere');
};
chomp($@);
ASSERT($@, "Error trapped: $@");
