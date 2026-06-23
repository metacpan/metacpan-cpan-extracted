use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Moo;

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

# Text generation works WITHOUT Moo installed
my $code = DBIO::Generate::Style::Moo->emit($spec);

like $code, qr/^package My::Schema::Result::Artist;/m, 'package line';
like $code, qr/use Moo;/,                          'use Moo in generated text';
like $code, qr/extends 'DBIO::Core'/,              'extends base class';
like $code, qr/__PACKAGE__->table\('artists'\)/, 'table call';
like $code, qr/^1;/m,                             'ends with 1';

# Text is stable - run twice, same result
my $code2 = DBIO::Generate::Style::Moo->emit($spec);
is $code2, $code, 'emit is deterministic';

# Optionally load generated code if Moo + MooX::NonMoose are present
SKIP: {
  eval { require Moo; require MooX::NonMoose; 1 }
    or skip 'Moo and/or MooX::NonMoose not installed — skipping load test', 1;

  eval $code;
  ok !$@, 'generated Moo class loads without error' or diag $@;
}

done_testing;