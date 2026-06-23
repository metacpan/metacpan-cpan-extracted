use strict; use warnings;
use Test::More;
use DBIO::Adapter::Base ();

my $base = DBIO::Adapter::Base->new;
eval { $base->to_native({ base_type => 'integer' }) };
like $@, qr/to_native not implemented/, 'base to_native dies';

is_deeply $base->capabilities, { supports_alter_column_type => 1 },
  'default capabilities';

{
  package My::Adapter;
  use base 'DBIO::Adapter::Base';
  sub to_native { 'FAKE_' . uc $_[1]->{base_type} }
}
is( My::Adapter->new->to_native({ base_type => 'integer' }), 'FAKE_INTEGER',
  'subclass to_native works' );

done_testing;
