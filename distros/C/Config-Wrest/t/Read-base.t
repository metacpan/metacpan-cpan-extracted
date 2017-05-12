#!/usr/local/bin/perl

#
# Basic functionality
# $Id: Read-base.t,v 1.6 2006/04/18 14:02:29 piersk Exp $

use strict;
use Getopt::Std;
use lib("./lib","../lib");
use Config::Wrest;
use Test::Assertions('test');
use Log::Trace;
use Cwd;

use vars qw($opt_t $opt_T);

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	deep_import Log::Trace qw(print);
}

#So if can find config files even when run from make
chdir 't' if -d 't';
my $root=cwd;

plan tests;

my $cr;

# use the constructor
ASSERT( $cr = Config::Wrest->new( UseQuotes => 0, Escapes => 0 ), 'new object' );
DUMP('Object', $cr);

my $vardata = $cr->parse_file("$root/data/Reader_1.cfg");
DUMP('Variables', $vardata);

# normal top-level values
ASSERT( $vardata->{"Name"} eq 'Value1', 'simplest top-level value case');
ASSERT( $vardata->{"Name2"} eq 'Value2', 'simplest top-level value case');

# check default behaviours
ASSERT( $vardata->{"DELIMITER"} eq q/"	"/, 'default: no quoting' );	# quoting
ASSERT( $vardata->{"THING"} eq q/'foo'/, 'default: no quoting' );		# quoting
ASSERT( $vardata->{"hashmark"} eq q/%23/, 'default: no escape sequences' );		# escaping


# do it again, but differently
ASSERT( ($cr = new Config::Wrest( UseQuotes => 0, Escapes => 0 )), 'new object without filename' );
$vardata = $cr->parse_file("$root/data/Reader_1.cfg");
ASSERT( $vardata, 'explicitly parse a file' );

# normal top-level values
ASSERT( $vardata->{"Name"} eq 'Value1', 'simplest top-level value case');
ASSERT( $vardata->{"Name2"} eq 'Value2', 'simplest top-level value case');

# check default behaviours
ASSERT( $vardata->{"DELIMITER"} eq q/"	"/, 'default: no quoting' );	# quoting
ASSERT( $vardata->{"THING"} eq q/'foo'/, 'default: no quoting' );		# quoting
ASSERT( $vardata->{"hashmark"} eq q/%23/, 'default: no escape sequences' );		# escaping


# ok let's check non-defaults
ASSERT( $cr = new Config::Wrest( UseQuotes => 1, Escapes => 1 ), 'new object'  );
DUMP('Object', $cr);

$vardata = $cr->parse_file("$root/data/Reader_1.cfg");
DUMP('Variables', $vardata);

ASSERT( $vardata->{"DELIMITER"} eq "\t", '<'.$vardata->{"DELIMITER"}.'>' );	# quoting
ASSERT( $vardata->{"THING"} eq q/foo/, '<'.$vardata->{"THING"}.'>' );		# quoting
ASSERT( $vardata->{"hashmark"} eq q/#/ , '<'.$vardata->{"hashmark"}.'>');		# escaping
ASSERT( $vardata->{'Name3'} eq 'Value3', '<'.$vardata->{"Name3"}.'>' );


# now check that the deserialize method is OK
$cr = new Config::Wrest( UseQuotes => 1, Escapes => 1 );
my $str = READ_FILE("$root/data/Reader_1.cfg");
my $vardata2 = $cr->deserialize($str);
DUMP("Variables 2", $vardata2);
ASSERT(EQUAL($vardata, $vardata2), 'deserialize and parse_file give same result');

# ensure it works with string refs
my $vardata3 = $cr->deserialize(\$str);
DUMP("Variables 3", $vardata3);
ASSERT(EQUAL($vardata, $vardata3), 'deserialize and parse_file give same result');
ASSERT(EQUAL($vardata2, $vardata3), 'deserialize and deserialize(ref) give same result');

# ensure that defaults are correctly set
$cr = new Config::Wrest();
$vardata = $cr->deserialise("foo 'ba%20r'\nqux");
ASSERT($vardata->{'foo'} eq "ba r", "defaults OK");
ASSERT((defined($vardata->{'qux'}) && $vardata->{'qux'} eq ""), "defaults OK");

$cr = new Config::Wrest( Escapes => 1, UseQuotes => 1 );
$vardata = $cr->deserialise("foo 'ba%20r'\nqux");
ASSERT($vardata->{'foo'} eq "ba r", "defaults OK");
ASSERT((defined($vardata->{'qux'}) && $vardata->{'qux'} eq ""), "defaults OK");

$cr = new Config::Wrest( Escapes => 0, UseQuotes => 0 );
$vardata = $cr->deserialise("foo 'ba%20r'\nqux");
ASSERT($vardata->{'foo'} eq "'ba%20r'", "non-defaults OK");

# check the header handling
$cr = new Config::Wrest();
$vardata = $cr->deserialise("foo 'ba%20r'\nqux");
ASSERT(EQUAL($vardata, {
	foo => 'ba r',
	qux => ''
}), "Deserialized OK, header lines read");
$str = $cr->serialise($vardata);
TRACE(">>>$str<<<");

my @lines = split(/\n/, $str);
ASSERT(@lines==10, "serialized to right number of lines");

$cr = new Config::Wrest( WriteWithHeader => 0 );
my $str_nohead = $cr->serialise($vardata);
TRACE(">>>$str_nohead<<<");

@lines = split(/\n/, $str_nohead);
ASSERT(@lines==2, "serialized to right number of lines (no header)");

# use different options to check that the directives really get read
$cr = new Config::Wrest( AllowEmptyValues => 0, Escapes => 0, UseQuotes => 0 );
$vardata = $cr->deserialise($str);
DUMP("Variables", $vardata);
ASSERT(EQUAL($vardata, {
	foo => 'ba r',
	qux => ''
}), "Deserialized OK, header lines read");

$vardata = $cr->deserialise($str_nohead);
DUMP("Variables", $vardata);
ASSERT(EQUAL($vardata, {
	foo => "'ba%20r'",
	qux => "''"
}), "Deserialized OK, no header lines");


eval {
	$cr->deserialize({});
};
chomp($@);
ASSERT($@, "Bad reference trapped: $@");
