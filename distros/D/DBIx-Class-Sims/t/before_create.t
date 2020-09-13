# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

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
          sim => { value => 'abcxyz' },
        },
        derived_name => {
          data_type => 'varchar',
          size => 128,
          is_nullable => 0,
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use common qw(sims_test);

sims_test "Modify provided value in before_create" => {
  spec => [
    {
      Artist => [
        { name => 'xyz' },
      ],
    },
    {
      hooks => {
        before_create => sub {
          my ($source, $item) = @_;
          if ($source->name eq 'Artist') {
            my $name = $item->value('name');
            $name =~ s/x//;
            $item->set_value(name => $name);

            $item->set_value(derived_name => uc($name));
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => 'yz', derived_name => 'YZ' },
  },
  rv => {
    Artist => { id => 1, name => 'yz', derived_name => 'YZ' },
  },
};

sims_test "Modify generated value in before_create" => {
  spec => [
    {
      Artist => 1,
    },
    {
      hooks => {
        before_create => sub {
          my ($source, $item) = @_;
          if ($source->name eq 'Artist') {
            my $name = $item->value('name');
            $name =~ s/x//;
            $item->set_value(name => $name);

            $item->set_value(derived_name => uc($name));
          }
        },
      },
    },
  ],
  expect => {
    Artist => { id => 1, name => 'abcyz', derived_name => 'ABCYZ' },
  },
  rv => {
    Artist => { id => 1, name => 'abcyz', derived_name => 'ABCYZ' },
  },
};

done_testing;
