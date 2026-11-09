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
like $code, qr/has_column ['"]?id['"]?/,               'has_column for id';
like $code, qr/has_column ['"]?name['"]?/,             'has_column for name';
like $code, qr/varchar/,                               'varchar type';
like $code, qr/200/,                                   'size 200';
like $code, qr/^1;/m,                                  '1 at end';

# The emitted DSL must COMPILE under the actual DBIO::Candy and round-trip.
# has_column wraps a FLAT key/value list into the column-info hashref, so the
# data_type must survive as data_type -- the old `'type', { ... }` form stored
# { type => {...} } with no data_type, which only a round-trip check catches.
my $compiled = eval $code; ## no critic (ProhibitStringyEval)
is $@, '', 'emitted Candy code compiles under use DBIO::Candy' or diag $code;
ok $compiled, 'emitted Candy code returns true';

is_deeply [ My::Schema::Result::Artist->columns ], [qw/id name/],
  'columns round-trip';
is_deeply [ My::Schema::Result::Artist->primary_columns ], [qw/id/],
  'primary key round-trips';
is My::Schema::Result::Artist->column_info('name')->{data_type}, 'varchar',
  'name data_type round-trips (not swallowed into the key)';
is My::Schema::Result::Artist->column_info('name')->{size}, 200,
  'name size round-trips';
ok My::Schema::Result::Artist->column_info('id')->{is_auto_increment},
  'id is_auto_increment round-trips';

# Second spec: a NON-EMPTY components list. DBIO::Candy loads components via
# `use DBIO::Candy -components => [...]`, not a bareword load_components call.
my $spec_c = {
  moniker      => 'Event',
  class        => 'My::Schema::Result::CandyEvent',
  table        => 'events',
  column_order => [qw/id created/],
  columns      => {
    id      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    created => { data_type => 'datetime', is_nullable => 1 },
  },
  pk               => [qw/id/],
  uniq             => [],
  relationships    => [],
  extra_statements => [],
  is_view          => 0,
  view_definition  => undef,
  result_base_class => 'DBIO::Core',
  components        => ['InflateColumn::DateTime'],
  additional_classes => [],
};

my $code_c = DBIO::Generate::Style::Candy->emit($spec_c);

like $code_c, qr/use DBIO::Candy -components => \[.*InflateColumn::DateTime.*\];/,
  'components emitted via -components import option';
unlike $code_c, qr/^load_components\b/m,
  'no bareword load_components (not a Candy export)';

my $compiled_c = eval $code_c; ## no critic (ProhibitStringyEval)
is $@, '', 'Candy code with components compiles' or diag $code_c;
ok My::Schema::Result::CandyEvent->isa('DBIO::InflateColumn::DateTime'),
  'component loaded via -components';
is My::Schema::Result::CandyEvent->column_info('created')->{data_type}, 'datetime',
  'created data_type round-trips';

done_testing;
