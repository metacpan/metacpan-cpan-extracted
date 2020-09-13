# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing ok );

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

# This highlights an issue where we cannot create a ::Relationship object
# without the ::Source and the ::Source creates all its relationships
# immediateley within initialize().
=pod
my $rel = DBIx::Class::Sims::Relationship->new(
  name => 'bar',
  source => DBIx::Class::Sims::Source->new(
    name => 'Foo',
    runner => DBIx::Class::Sims::Runner->new(
      schema => Schema,
    ),
  ),
  info => {
    cond => {
      'foreign.id' => 'self.bar_id',
    },
    source => 'MyApp::Bar',
    attrs => {
      is_foreign_key_constraint => 1,
    },
  },
);
=cut
ok 1;

done_testing;
