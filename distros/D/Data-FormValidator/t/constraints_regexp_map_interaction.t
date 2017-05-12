#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perllib';
use Test::More qw/no_plan/;
use Data::FormValidator;

my $input_profile = {
  required    => ['email_field'],
  constraints => {
    email_field => ['email'],
  } };

my $input_hashref = { email_field => 'test@bad_email', };

my $results;
eval {
  $results = Data::FormValidator->check( $input_hashref, $input_profile );
};
is( $@, '', "Survived validate" );

my @invalids = $results->invalid;
is( scalar @invalids, 1, "Correctly catches the bad field" );
is( $invalids[0], 'email_field',
  "The invalid field is listed correctly as 'email_field'" );

# Now add constraint_regexp_map to the profile, and we'll get a weird interaction...

my $regex = qr/^test/;
$input_profile->{constraint_regexp_map} = { qr/email_/ => $regex };

eval {
  $results = Data::FormValidator->check( $input_hashref, $input_profile );
};
is( $@, '', "Survived validate" );

@invalids = $results->invalid;
is( scalar @invalids, 1, "Still correctly catches the bad field" );
is( $invalids[0], 'email_field',
  "The invalid field is still listed correctly as 'email_field'" );

ok( $input_hashref->{email_field} =~ $regex,
  "But perl agrees that the email address does match the regex" );
