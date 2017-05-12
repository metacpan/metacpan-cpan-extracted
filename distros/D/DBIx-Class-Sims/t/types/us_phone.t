# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_phone');

my @tests = (
  [ { data_type => 'varchar', size => 6 }, qr/^$/ ],
  [ { data_type => 'varchar', size => 7 }, qr/^\d{7}$/ ],
  [ { data_type => 'varchar', size => 8 }, qr/^\d{3}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 9 }, qr/^\d{3}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 10 }, qr/^\d{10}$/ ],
  [ { data_type => 'varchar', size => 11 }, qr/^\d{10}$/ ],
  [ { data_type => 'varchar', size => 12 }, qr/^\d{3}-\d{3}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 13 }, qr/^\(\d{3}\)\d{3}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 14 }, qr/^\(\d{3}\) \d{3}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 15 }, qr/^\(\d{3}\) \d{3}-\d{4}$/ ],
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'us_phone' };
  like( $sub->($test->[0]), $test->[1] );
}

done_testing;
