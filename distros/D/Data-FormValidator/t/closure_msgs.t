#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints qw(
  email
  FV_eq_with
);

# Test that closures and custom messages work in combination.
# Addresses this reported bug: #73235: msgs lookup doesn't work for built in closures
# https://rt.cpan.org/Ticket/Display.html?id=73235
my $result = Data::FormValidator->check(
  { email => 'a', email_confirm => 'b' },
  {
    required           => [qw( email email_confirm )],
    constraint_methods => {
      email => [ email(), FV_eq_with('email_confirm') ],
    },
    msgs => {
      constraints => {
        email   => 'Invalid Email Address',
        eq_with => 'Must match confirmation'
      },
    } } );
like(
  $result->msgs->{email},
  qr/Email Address/,
  "custom message for email() works"
);
like(
  $result->msgs->{email},
  qr/Must Match/i,
  "custom message for FV_eq_with() works"
);

done_testing();
