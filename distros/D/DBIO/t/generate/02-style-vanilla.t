use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Vanilla;

my $spec = {
  moniker      => 'Artist',
  class        => 'My::Schema::Result::Artist',
  table        => 'artists',
  column_order => [qw/id name/],
  columns      => {
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
  },
  pk              => [qw/id/],
  uniq            => [],
  relationships   => [
    { method => 'has_many',
      args   => [ 'cds', 'My::Schema::Result::CD',
                  { 'foreign.artist_id' => 'self.id' }, {} ] },
  ],
  extra_statements => [],
  is_view          => 0,
  view_definition  => undef,
  result_base_class => 'DBIO::Core',
  components        => [],
  additional_classes => [],
};

my $code = DBIO::Generate::Style::Vanilla->emit($spec);

like $code, qr/^package My::Schema::Result::Artist;/m, 'package declaration';
like $code, qr/use base 'DBIO::Core';/,               'use base';
like $code, qr/__PACKAGE__->table\('artists'\);/,      'table call';
like $code, qr/__PACKAGE__->add_columns\(/,            'add_columns call';
like $code, qr/id\s*=>/,                               'id column';
like $code, qr/name\s*=>/,                             'name column';
like $code, qr/__PACKAGE__->set_primary_key\('id'\)/,  'set_primary_key';
like $code, qr/has_many/,                              'has_many relationship';
like $code, qr/'cds'/,                                'rel name';
like $code, qr/My::Schema::Result::CD/,                'remote class';
like $code, qr/^1;/m,                                  'ends with 1';

# Verify emitted code is valid Perl: eval it unchanged, it declares and
# populates My::Schema::Result::Artist itself
my $compiled = eval $code;
is $@, '', 'emitted code compiles';
ok $compiled, 'emitted code returns true';
ok( My::Schema::Result::Artist->can('table'), 'class set up via use base' );

done_testing;
