# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_city');

my @tests = (
  [ { data_type => 'varchar' }, qr/^[\w\s]+$/ ],
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'us_city' };
  like( $sub->($test->[0]), $test->[1] );
}

done_testing;
