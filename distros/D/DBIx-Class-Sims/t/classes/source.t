# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest ok is bag item );

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
      unique_constraints => [ [ 'name' ] ],
      belongs_to => {
        artist => { Artist => 'artist_id' },
      },
    },
  ]);
}

use common qw( Schema );

my $runner = DBIx::Class::Sims::Runner->new(
  # Other attributes aren't needed for these tests
  schema => Schema,
);

subtest 'parent' => sub {
  my $artist = DBIx::Class::Sims::Source->new(
    name   => 'Artist',
    runner => $runner,
  );

  #is($artist->runner, $runner, 'The runner() accessor returns correctly');

  ok(!$artist->column('id')->is_in_fk, 'artist.id is NOT in a FK');
  ok(!$artist->column('name')->is_in_fk, 'artist.name is NOT in a FK');

  my @rels = map { $_->name } $artist->relationships;
  is(\@rels, ['albums'], "One relationships overall");

  my @parent_rels = map { $_->name } $artist->parent_relationships;
  is(\@parent_rels, [], "No parent relationships");

  my @child_rels = map { $_->name } $artist->child_relationships;
  is(\@child_rels, ['albums'], "One child relationships");

  #my @c_primary = map { $_->name } $artist->columns({ is_in_pk => 1 });
  #is(\@c_primary, ['id'], "Correct PK columns");
  #my @c_in_uk = map { $_->name } $artist->columns({ is_in_uk => 1 });
  #is(\@c_in_uk, ['id'], "Correct UK columns");
  #my @c_normal = map { $_->name } $artist->columns({ is_in_uk => 0 });
  #is(\@c_normal, ['name'], "Correct normal columns");
};

subtest 'child' => sub {
  my $album = DBIx::Class::Sims::Source->new(
    name   => 'Album',
    runner => $runner,
  );
  #is($album->runner, $runner, 'The runner() accessor returns correctly');
  ok(!$album->column('id')->is_in_fk, 'album.id is NOT in a FK');
  ok(!$album->column('name')->is_in_fk, 'album.name is NOT in a FK');
  ok($album->column('artist_id')->is_in_fk, 'album.artist_id IS in a FK');

  my @rels = map { $_->name } $album->relationships;
  is(\@rels, ['artist'], "One relationships overall");

  my @parent_rels = map { $_->name } $album->parent_relationships;
  is(\@parent_rels, ['artist'], "One parent relationships");

  my @child_rels = map { $_->name } $album->child_relationships;
  is(\@child_rels, [], "No child relationships");

  #my @c_primary = map { $_->name } $album->columns({ is_in_pk => 1 });
  #is(\@c_primary, ['id'], "Correct PK columns");
  #my @c_in_uk = map { $_->name } $album->columns({ is_in_uk => 1 });
  #is(\@c_in_uk, bag{item 'id'; item 'name'}, "Correct UK columns");
  #my @c_normal = map { $_->name } $album->columns({ is_in_uk => 0 });
  #is(\@c_normal, ['artist_id'], "Correct normal columns");
};

done_testing;
