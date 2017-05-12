#!/usr/bin/env perl
#vi:sw=2

use 5.010_000;

my $CLASS;
BEGIN {
  $CLASS = $ENV{SIMS_CLASS} // die "Must set the class as SIMS_CLASS\n";

  # require doesn't work, but this does.
  eval "use $CLASS";
  die $@ if $@;
}

use Web::Simple $CLASS;

$CLASS->run_if_script;
