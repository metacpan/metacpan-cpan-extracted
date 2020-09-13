# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest E match ok );

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
        albums => { Album => 'parent_id' },
      },
    },
    Writer => {
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
        albums => { Album => 'parent_id' },
      },
    },
    Album => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
        parent_id => {
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
        artist => { Artist => 'parent_id' },
        writer => { Writer => 'parent_id' },
      },
    },
  ]);
}

use common qw(sims_test);

foreach my $parent_class (qw( Writer Artist )) {
  sims_test "$parent_class via column" => {
    skip_foreign_keys => 1,
    load_sims => sub {
      my ($schema) = @_;
      my $rv = $schema->load_sims({
        $parent_class => 1,
      });

      return $schema->load_sims({
        Album => { parent_id => $rv->{$parent_class}[0] },
      });
    },
    expect => {
      Album => { id => 1, name => E(), parent_id => 1 },
    },
    rv => sub { { Album => shift->{expect}{Album} } },
  };

  my $rel = lc $parent_class;
  sims_test "$parent_class via $rel" => {
    skip_foreign_keys => 1,
    load_sims => sub {
      my ($schema) = @_;
      my $rv = $schema->load_sims({
        $parent_class => 1,
      });

      return $schema->load_sims({
        Album => { $rel => $rv->{$parent_class}[0] },
      });
    },
    expect => {
      Album => { id => 1, name => E(), parent_id => 1 },
    },
    rv => sub { { Album => shift->{expect}{Album} } },
  };
}

done_testing;
