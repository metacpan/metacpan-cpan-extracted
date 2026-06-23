package # hide from PAUSE
    MigrationsTest::Schema::Money;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('money_test');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'amount' => {
    data_type => 'money',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;
