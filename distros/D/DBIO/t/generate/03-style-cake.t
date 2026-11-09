use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Cake;

my $spec = {
  moniker      => 'CD',
  class        => 'My::Schema::Result::CD',
  table        => 'cd',
  column_order => [qw/cdid title year/],
  columns      => {
    cdid  => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    title => { data_type => 'varchar', size => 100, is_nullable => 0 },
    year  => { data_type => 'integer', is_nullable => 1 },
  },
  pk              => [qw/cdid/],
  uniq            => [],
  relationships   => [
    { method => 'belongs_to',
      args   => [ 'artist', 'My::Schema::Result::Artist',
                  { 'foreign.id' => 'self.artist_id' }, {} ] },
  ],
  extra_statements  => [],
  is_view           => 0,
  view_definition   => undef,
  result_base_class => 'DBIO::Core',
  components        => [],
  additional_classes => [],
};

my $code = DBIO::Generate::Style::Cake->emit($spec);

like $code, qr/^package My::Schema::Result::CD;/m,     'package line';
like $code, qr/use DBIO::Cake/,                        'use DBIO::Cake';
like $code, qr/^table ['"]cd['"];/m,                   'table DSL';
# DBIO::Cake has no primary_column/column/nullable_column; columns are the
# `col NAME => <type>[, <modifier>]` DDL form, PK is a separate primary_key.
like $code, qr/^col ['"]cdid['"]\s*=>.*\bauto_inc\b/m, 'col DSL for pk cdid with auto_inc';
like $code, qr/^primary_key ['"]cdid['"];/m,           'primary_key DSL';
like $code, qr/^col ['"]title['"]\s*=>/m,              'col DSL for title';
like $code, qr/^col ['"]year['"]\s*=>.*\bnull\b/m,     'nullable col year carries null modifier';
like $code, qr/varchar\(100\)/,                        'varchar size inline';
like $code, qr/belongs_to ['"]artist['"]/,            'belongs_to rel';
like $code, qr/^1;/m,                               'ends with 1';

# The real regression: the emitted DSL must COMPILE under the actual
# DBIO::Cake and round-trip to the intended columns / PK / nullability.
my $compiled = eval $code; ## no critic (ProhibitStringyEval)
is $@, '', 'emitted Cake code compiles under use DBIO::Cake' or diag $code;
ok $compiled, 'emitted Cake code returns true';

is_deeply [ My::Schema::Result::CD->columns ], [qw/cdid title year/],
  'columns round-trip in order';
is_deeply [ My::Schema::Result::CD->primary_columns ], [qw/cdid/],
  'primary key round-trips';
ok My::Schema::Result::CD->column_info('cdid')->{is_auto_increment},
  'cdid is_auto_increment round-trips';
is My::Schema::Result::CD->column_info('title')->{data_type}, 'varchar',
  'title data_type round-trips';
is My::Schema::Result::CD->column_info('title')->{size}, 100,
  'title size round-trips';
ok My::Schema::Result::CD->column_info('year')->{is_nullable},
  'year is_nullable round-trips';

# Second spec: exercise the component + unique-constraint DSL paths, which
# must also be valid DBIO::Cake (components via __PACKAGE__->load_components,
# unique constraints via the `unique` export -- not load_components/
# unique_constraint barewords, which Cake does not provide).
my $spec2 = {
  moniker      => 'Tag',
  class        => 'My::Schema::Result::CakeTag',
  table        => 'tag',
  column_order => [qw/id name/],
  columns      => {
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 64, is_nullable => 0 },
  },
  pk              => [qw/id/],
  uniq            => [ [ 'tag_name_uniq', ['name'] ] ],
  relationships   => [],
  extra_statements  => [],
  is_view           => 0,
  view_definition   => undef,
  result_base_class => 'DBIO::Core',
  components        => ['InflateColumn::DateTime'],
  additional_classes => [],
};

my $code2 = DBIO::Generate::Style::Cake->emit($spec2);

like $code2, qr/__PACKAGE__->load_components\(['"]InflateColumn::DateTime['"]\)/,
  'components emitted via __PACKAGE__->load_components';
unlike $code2, qr/^load_components\b/m,
  'no bareword load_components (not a Cake export)';
like $code2, qr/^unique ['"]tag_name_uniq['"]\s*=>\s*\[/m,
  'unique constraint via the unique DSL';

my $compiled2 = eval $code2; ## no critic (ProhibitStringyEval)
is $@, '', 'Cake code with components + unique compiles' or diag $code2;
ok My::Schema::Result::CakeTag->isa('DBIO::InflateColumn::DateTime'),
  'component loaded at compile time';
is_deeply [ My::Schema::Result::CakeTag->result_source_instance
              ->unique_constraint_columns('tag_name_uniq') ],
  [qw/name/], 'unique constraint registered on the expected column';

done_testing;
