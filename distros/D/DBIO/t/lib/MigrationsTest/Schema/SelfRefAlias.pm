package # hide from PAUSE
    MigrationsTest::Schema::SelfRefAlias;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('self_ref_alias');
__PACKAGE__->add_columns(
  'self_ref' => {
    data_type => 'integer',
  },
  'alias' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key(qw/self_ref alias/);

__PACKAGE__->belongs_to( self_ref => 'MigrationsTest::Schema::SelfRef' );
__PACKAGE__->belongs_to( alias => 'MigrationsTest::Schema::SelfRef' );

1;
