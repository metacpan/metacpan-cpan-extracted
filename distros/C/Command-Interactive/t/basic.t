#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use File::Temp ();
use IO::File;
use Test::More (tests => 22);
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;
use POSIX qw(locale_h);
use locale;

# Test 1. Create a simple expected interaction
# and verify that it works "echo yes"
my $interaction = Command::Interactive::Interaction->new({
        expected_string => 'yes',
        is_required     => 1,
});

my $command = Command::Interactive->new({interactions => [$interaction],});

is($command->run("echo yes"),      undef,                                                   "Run command successfully");
is($command->run("echo no"),       "Failed to encounter required string 'yes' before exit", "Catch expected failure");
is($command->run("echo yes 2>&1"), undef,                                                   "Do not trigger 2>&1 appending");
is(
    $command->run("echo 'yes\nyes'"),
    "Got string 'yes', which matched expected string 'yes'. This was occurrence #2, which exceeds the specified limit of 1 occurrence(s) set for this string",
    "Two occurrences of a string that was expected only once"
);

$interaction->is_error(1);
is($command->run("echo yes"), "Got error string 'yes', which matched error detection string 'yes'", "Detect known error strings");

$command->interactions([]);
like($command->run("asdfasdf"), qr/Could not execute asdfasdf/, "Bogus command");
is($command->run("false"), 'Error executing false: ', "Command returning non-zero value");

$command->always_use_expect(1);
is($command->run("echo yes"), undef, "Force trivial command to use Expect with always_use_expect()");
is($command->run("false"), 'Got back return value 256 from false', "exitstatus detection from Expect");

my ($tempfh, $tempfile) = File::Temp::tempfile(CLEANUP => 1);
is(defined($tempfh), 1, "Created a temporary file for output stream testing");
$command->output_stream($tempfh);
$command->echo_output(1);
my $test_string = "This is a test string";
is($command->run("echo '$test_string'"), undef, "Echo some output");
$tempfh->close;
$tempfh = IO::File->new($tempfile);
is(defined($tempfh), 1, "Re-open temporary file for output stream testing");
my $contents = join('', <$tempfh>);
chomp($contents);
is($contents, $test_string, "Contents from output file match original string");
$tempfh->close;

($tempfh, $tempfile) = File::Temp::tempfile(CLEANUP => 1);
is(defined($tempfh), 1, "Created a temporary file for output stream testing");
$command->output_stream($tempfh);
$command->echo_output(1);
$command->web_format(1);
is($command->run("echo '$test_string'"), undef, "Echo some output");
$tempfh->close;
$tempfh = IO::File->new($tempfile);
is(defined($tempfh), 1, "Re-open temporary file for output stream testing");
$contents = join('', <$tempfh>);
is($contents, $test_string . "<br/>\n", "Contents from output file match original string (web format)");
$tempfh->close;

$command->echo_output(0);
$command->web_format(0);

($tempfh, $tempfile) = File::Temp::tempfile(CLEANUP => 1);
is(defined($tempfh), 1, "Created a temporary file for debug logfile testing");
$tempfh->close;
$command->debug_logfile($tempfile);
is($command->run("echo yes"), undef, "Executed command to force a write to debugging log");
$tempfh = IO::File->new($tempfile);
is(defined($tempfh), 1, "Re-open temporary file for debug log testing");
$contents = join('', <$tempfh>);
$tempfh->close;
like($contents, qr/Using Expect to spawn command: echo yes/, "debug logging works");

1;
