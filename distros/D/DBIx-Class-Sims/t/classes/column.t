# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest ok );

# It's not clear this will ever be needed, but it's clear we don't need it now.
=pod
use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Artist => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      has_many => {
        albums => { Album => 'artist_id' },
      },
    },
    Album => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        artist_id => {
          data_type => 'int',
          is_nullable => 0,
        },
        name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
      },
    },
  ]);
}

use common qw(Schema);
=cut

use DBIx::Class::Sims;

my $source = bless {
  runner => { predictable_values => 0 },
}, 'DBIx::Class::Sims::Source';

subtest 'normal' => sub {
  my $col = DBIx::Class::Sims::Column->new(
    source => $source,
    name => 'bar',
    info => {
      data_type => 'int',
      is_nullable => 0,
      is_auto_increment => 1,
    },
  );

  ok(!$col->is_in_pk, "Column returns it's NOT in a PK");
  ok(!$col->is_in_uk, "Column returns it's NOT in a UK");
};

subtest 'primary key' => sub {
  my $col = DBIx::Class::Sims::Column->new(
    source => $source,
    name => 'bar',
    info => {
      data_type => 'int',
      is_nullable => 0,
      is_auto_increment => 1,
    },
  );
  $col->in_pk(1);
  $col->in_uk('primary');

  ok($col->is_in_pk, "Column returns it's in a PK");
  ok($col->is_in_uk, "Column returns it's in a UK");
};

subtest 'unique key' => sub {
  my $col = DBIx::Class::Sims::Column->new(
    source => $source,
    name => 'bar',
    info => {
      data_type => 'int',
      is_nullable => 0,
      is_auto_increment => 1,
    },
  );
  $col->in_uk(1);

  ok(!$col->is_in_pk, "Column returns it's NOT in a PK");
  ok($col->is_in_uk, "Column returns it's in a UK");
};

done_testing;
