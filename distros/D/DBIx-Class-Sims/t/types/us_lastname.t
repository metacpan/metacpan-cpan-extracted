# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok 'DBIx::Class::Sims::Types';

my $sub = DBIx::Class::Sims::Types->can('us_lastname');

my $info = {
  data_type => 'varchar',
  sim => { type => 'us_lastname' },
};
my $expected = qr/^[\w']+(?: \w+)?(?: .+)?$/;
for ( 1 .. 1000 ) {
  like( $sub->($info), $expected );
}

done_testing;
