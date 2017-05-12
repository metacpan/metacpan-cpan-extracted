#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use_ok('Data::FormValidator');

# in response to bug report 2006/10/25 by Brian E. Lozier <brian@massassi.net>
# test script by Evan A. Zacks <zackse@cpan.org>
#
# The problem was that when specifying constraint_methods in a profile and
# using the name of a built-in (e.g., "zip") as the constraint, the built-in
# (match_zip or valid_zip) ended up being called as a method rather than a
# function.
#
# So now we throw an error if a non-code-ref is used with a constraint method.
my $err_re = qr/not a code ref/;

{
  my %profile = (
    required           => ['zip'],
    constraint_methods => {
      zip => 'zip',
    } );

  my %data = ( zip => 56567 );

  eval { my $r = Data::FormValidator->check( \%data, \%profile ) };
  like( $@, $err_re, "error thrown when given a string to constraint_method" );
}

{
  my %profile = (
    required           => ['zip'],
    constraint_methods => {
      zip => ['zip'],
    } );

  my %data = ( zip => 56567 );

  eval { my $r = Data::FormValidator->check( \%data, \%profile ) };
  like( $@, $err_re,
    "error thrown when given a string to constraint_method...even as part of a list."
  );
}

{
  my %profile = (
    required                => ['zip'],
    untaint_all_constraints => 1,
    constraint_methods      => { zip => {} } );

  my %data = ( zip => 56567 );

  eval { my $r = Data::FormValidator->check( \%data, \%profile ) };
  like( $@, $err_re,
    "error thrown when given a string to constraint_method...even as hash declaration."
  );
}
