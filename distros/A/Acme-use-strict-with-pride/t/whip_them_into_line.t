#!/usr/local/bin/perl -w
use strict;

use lib 't';
use Test::More tests => 9;
use GagMe;

$SIG{__WARN__} = sub {print STDERR $_[0]};

use Acme::use::strict::with::pride;

ok(1); # If we made it this far, we're ok.

my $debug = tie *STDERR, 'GagMe';

is (eval "require Bad; 2", 2, "Should be able to use Bad");
is ($@, "", "without an error");
is ($::loaded{Bad}, 1, "Bad did actually get loaded?");
like ($debug->read,
  qr!^Use of uninitialized value(?: \$a)? in addition \(\+\) at t/Bad.pm line 6\.$!,
      "Is the error properly mangled");

is (eval "use Naughty; 2", undef, "Should not be able to use Naughty");
like ($@, qr!Global symbol "\$what_am_i" requires explicit package name at t/Naughty.pm line 4.!,
      "Is the error properly mangled");

is ($debug->read, '', "eval should have caught the error");

is ($::loaded{Naughty}, 1, "Naughty did actually get loaded?");

undef $debug;
untie *STDERR;
