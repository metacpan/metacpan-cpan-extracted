#!/usr/local/bin/perl
# as we want to let the naughty modules do their thing we can't use the -w flag
# irritatingly warnings come out on the underlying IO STDERR, rather than
# anything tied to the file handle.
use strict;

use lib 't';
use Test::More tests => 8;
use GagMe;

# Aargh. WTF is test harness doing turning on warnings when I explicity
# don't want them?
$^W = 0;

$SIG{__WARN__} = sub {print STDERR $_[0]};

# Test things misbehave as expected without Acme::use::strict::with::pride

my $debug = tie *STDERR, 'GagMe';

is (eval "require Bad; 2", 2, "Should be able to use Bad");
is ($@, "", "without an error");
is ($::loaded{Bad}, 1, "Bad did actually get loaded?");
is ($debug->read, '', "There should be no warnings");

is (eval "use Naughty; 2", 2, "Should be able to use Naughty");
is ($@, "", "without an error");
is ($debug->read, '', "There should be no warnings");

is ($::loaded{Naughty}, 1, "Naughty did actually get loaded?");

undef $debug;
untie *STDERR;
