# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing bag item is );
use DBIx::Class::Sims;

is(
  [ DBIx::Class::Sims->sim_types ],
  bag {
    item 'email_address';
    item 'ip_address';
    item 'us_firstname';
    item 'us_lastname';
    item 'us_name';
    item 'us_address';
    item 'us_city';
    item 'us_county';
    item 'us_phone';
    item 'us_ssntin';
    item 'us_state';
    item 'us_zipcode';
  },
  "List of types as expected",
);

done_testing;
