#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

use IO::Handle;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use Capture::Tiny qw/ capture_stderr /; # bundled under t/lib

# make sure all test output supports utf
binmode( \$_, ":utf8" ) for *STDERR, *STDOUT;
$_->autoflush(1) for *STDERR, *STDOUT;

our $CLASS = "Acme::Throw";
use_ok $CLASS;
$CLASS->import;

# throw and catch an exception
my $die_msg = "your mom";
my ($got_val, $got_err);
my $stderr = capture_stderr {
  $got_val = eval { die "$die_msg\n"; };
  $got_err = $@;
};

# make sure die still worked
is $got_val, undef, "die didn't break";

# determine what should be output before the exception message
my $msg = $CLASS->_msg;
my $exp_output = <<END;
(╯°□°）╯︵ ┻━┻  $msg
$die_msg
END


# make sure original exception was not changed
is $got_err, "$die_msg\n", "orig exception unchanged";

#print STDERR "msg: [$msg] output: [$stderr]\n";
#TODO: {
#  is $stderr, $exp_output, "NOW WITH 100% MORE RAGE";
#};


done_testing;
