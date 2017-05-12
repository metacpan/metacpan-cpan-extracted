#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints::Dates qw( date_and_time );

eval { require Date::Calc; };
if ($@)
{
  plan skip_all => 'Date::Calc required for date testing';
}
else
{
  plan 'no_plan';
}

my $format = Data::FormValidator::Constraints::Dates::_prepare_date_format(
  'MM/DD/YYYY hh?:mm:ss pp');

my ( $date, $year, $month, $day, $hour, $min, $sec ) =
  Data::FormValidator::Constraints::Dates::_parse_date_format( $format,
  '12/02/2003 1:01:03 PM' );
ok( $date eq '12/02/2003 1:01:03 PM', 'returning untainted date' );
ok( $year == 2003,                    'basic date prepare and parse test' );
ok( $month == 12 );
ok( $day == 2 );
ok( $hour == 13 );
ok( $min == 1 );
ok( $sec == 3 );

# Now try again, leaving out PM, which may trigger a warning when it shouldn't
$format = Data::FormValidator::Constraints::Dates::_prepare_date_format(
  'MM/DD/YYYY hh?:mm:ss');
( $date, $year, $month, $day, $hour, $min, $sec ) =
  Data::FormValidator::Constraints::Dates::_parse_date_format( $format,
  '12/02/2003 1:01:03' );
is( $date, '12/02/2003 1:01:03', 'returning untainted date' );
ok( $year == 2003, 'basic date prepare and parse test' );
ok( $month == 12,  'month' );
ok( $day == 2,     'day' );
ok( $hour == 1,    'hour' );
ok( $min == 1,     'min' );
ok( $sec == 3,     'sec' );

my $simple_profile = {
  required           => [qw/date_and_time_field_bad date_and_time_field_good/],
  validator_packages => [qw/Data::FormValidator::Constraints::Dates/],
  constraint_methods => {
    'date_and_time_field_good' => date_and_time('MM/DD/YYYY hh:mm pp'),
    'date_and_time_field_bad'  => date_and_time('MM/DD/YYYY hh:mm pp'),
  },
  untaint_constraint_fields => [qw/date_and_time_field/],
};

my $simple_data = {
  date_and_time_field_good => '12/04/2003 02:00 PM',
  date_and_time_field_bad  => 'slug',
};

my $validator = new Data::FormValidator( {
  simple => $simple_profile,
} );

my ( $valids, $missings, $invalids, $unknowns ) = ( {}, [], {}, [] );
eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $simple_data, 'simple' );
};
ok( ( not $@ ), 'eval' )
  or diag $@;
ok( $valids->{date_and_time_field_good}, 'expecting date_and_time success' );
ok( ( grep /date_and_time_field_bad/, @$invalids ),
  'expecting date_and_time failure' );

{
  my $r = Data::FormValidator->check( {
      # Testing leap years
      date_and_time_field_good    => '02/29/2008',
      date_and_time_field_bad_pat => '02/29/2008',
      leap_seventy_six            => '02/29/1976',
    },
    {
      required => [qw/date_and_time_field_good date_and_time_field_bad_pat/],
      constraint_methods => {
        'date_and_time_field_good' => date_and_time('MM/DD/YY(?:YY)?'),

# This pattern actually tests with a 3 digit year, not a four digit year, and fails
# on the date 02/29/2008, because 02/29/200 doesn't exist.
        'date_and_time_field_bad_pat' => date_and_time('MM/DD/YYY?Y?'),
        'leap_seventy_six'            => date_and_time('MM/DD/YY(?:YY)?'),
      },
    } );
  my $valid = $r->valid;
  ok(
    $valid->{date_and_time_field_good},
    '02/29/2008 should pass MM/DD/YY(?:YY)?'
  );

TODO:
  {
    local $TODO = "leap year bug?";
    ok( $valid->{leap_seventy_six}, '02/29/1976 should pass MM/DD/YY(?:YY)?' );
  }

# This one fails not because the date is bad, but because the pattern is not sensible
# It would be better to detect that the pattern was bad and fail that way, of course.
  ok(
    $r->invalid('date_and_time_field_bad_pat'),
    "02/29/2008 should fail MM/DD/YYY?Y?"
  );
}
