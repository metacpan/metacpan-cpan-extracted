use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Candy;

my $spec = {
  moniker      => 'Artist',
  class        => 'My::Schema::Result::Artist',
  table        => 'artists',
  column_order => [qw/id name/],
  columns      => {
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 200, is_nullable => 0 },
  },
  pk               => [qw/id/],
  uniq             => [],
  relationships    => [],
  extra_statements => [],
  is_view          => 0,
  view_definition  => undef,
  result_base_class => 'DBIO::Core',
  components        => [],
  additional_classes => [],
};

my $code = DBIO::Generate::Style::Candy->emit($spec);

like $code, qr/^package My::Schema::Result::Artist;/m, 'package';
like $code, qr/use DBIO::Candy;/,                       'use DBIO::Candy';
like $code, qr/has_column id/,                         'has_column for id';
like $code, qr/has_column name/,                       'has_column for name';
like $code, qr/varchar/,                               'varchar type';
like $code, qr/200/,                                   'size 200';
like $code, qr/^1;/m,                                  '1 at end';

done_testing;