# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_state');

my @tests = (
  [ { data_type => 'varchar', size => 2 }, qr/^\w\w$/ ],
  [ { data_type => 'varchar', size => 10 }, qr/^[\w\s]{1,10}$/ ],
  [ { data_type => 'varchar', size => 12 }, qr/^[\w\s]{1,12}$/ ],
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'us_state' };
  like( $sub->($test->[0]), $test->[1] );
}

done_testing;
