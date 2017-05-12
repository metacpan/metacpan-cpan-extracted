# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_firstname');

my $info = {
  data_type => 'varchar',
  sim => { type => 'us_firstname' },
};
my $expected = qr/^\w+$/;
for ( 1 .. 1000 ) {
  like( $sub->($info), $expected );
}

done_testing;
