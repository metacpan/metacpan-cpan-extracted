#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Config;
$SIG{__WARN__} = \&carp;
$SIG{__DIE__}  = \&confess;

# A gift from Andy Lester, this trick shows me where eval's die.
my @args = (
  '-I./lib',
  (
      ( defined( $ENV{PERL5LIB} ) && length( $ENV{PERL5LIB} ) )
    ? ( map { "-I$_" } split( /$Config{path_sep}/, $ENV{PERL5LIB} ) )
    : ()
  ),
  '-T',
  './t/untaint.pl',
  qw(Jim Beam jim@foo.bar james@bar.foo 132.10.10.2 Monroe Rufus 12345 oops 0)
);

# We use $^X to make it easier to test with different versions of Perl.
system( $^X, @args );
