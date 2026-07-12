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
like $code, qr/^primary_column ['"]cdid['"]\s*=>/m,    'primary_column DSL';
like $code, qr/^column ['"]title['"]\s*=>/m,           'column DSL for title';
like $code, qr/varchar\(100\)/,                        'varchar size inline';
like $code, qr/belongs_to ['"]artist['"]/,            'belongs_to rel';
like $code, qr/^1;/m,                               'ends with 1';

done_testing;