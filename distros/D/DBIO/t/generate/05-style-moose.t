use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Moose;

my $spec = {
  moniker      => 'Tag',
  class        => 'My::Schema::Result::Tag',
  table        => 'tags',
  column_order => [qw/id label/],
  columns      => {
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    label => { data_type => 'varchar', size => 50, is_nullable => 0 },
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

# Text generation works WITHOUT Moose installed
my $code = DBIO::Generate::Style::Moose->emit($spec);

like $code, qr/^package My::Schema::Result::Tag;/m, 'package line';
like $code, qr/use Moose;/,                          'use Moose in generated text';
like $code, qr/extends ['"]DBIO::Core['"]/,          'extends base class';
like $code, qr/__PACKAGE__->table\(['"]tags['"]\)/,  'table call';
like $code, qr/^1;/m,                                'ends with 1';

# Text is stable - run twice, same result
my $code2 = DBIO::Generate::Style::Moose->emit($spec);
is $code2, $code, 'emit is deterministic';

# Optionally load generated code if Moose is present
SKIP: {
  eval { require Moose; require MooseX::NonMoose; require MooseX::MarkAsMethods; 1 }
    or skip 'Moose and/or MooseX extensions not installed — skipping load test', 1;

  eval $code;
  ok !$@, 'generated Moose class loads without error' or diag $@;
}

done_testing;