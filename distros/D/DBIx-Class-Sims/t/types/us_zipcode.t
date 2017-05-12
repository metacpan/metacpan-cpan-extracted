# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_zipcode');

my @tests = (
  [ { data_type => 'varchar', size => 9 }, qr/^\d{9}$/ ],
  [ { data_type => 'varchar', size => 10 }, qr/^\d{5}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 12 }, qr/^\d{5}-\d{4}$/ ],
  [ { data_type => 'varchar', size => 8 }, qr/^\d{5}$/ ],
  [ { data_type => 'varchar', size => 7 }, qr/^\d{5}$/ ],
  [ { data_type => 'varchar', size => 6 }, qr/^\d{5}$/ ],
  [ { data_type => 'varchar', size => 5 }, qr/^\d{5}$/ ],
  [ { data_type => 'varchar', size => 4 }, qr/^$/ ],
  [ { data_type => 'varchar', size => 3 }, qr/^$/ ],
  [ { data_type => 'varchar', size => 2 }, qr/^$/ ],
  [ { data_type => 'varchar', size => 1 }, qr/^$/ ],
  [ { data_type => 'int' }, qr/^\d{1,5}$/ ],
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'us_zipcode' };
  like( $sub->($test->[0]), $test->[1] );
}

done_testing;
