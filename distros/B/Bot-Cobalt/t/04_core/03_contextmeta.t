use Test::More tests => 14;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::Core::ContextMeta');
}

my $cmeta = new_ok('Bot::Cobalt::Core::ContextMeta');

ok( 
  $cmeta->add('Context', 'Key', { AddedAt => 1, ThisMeta => 'String' } ),
  'ContextMeta add'
);

ok( 
  $cmeta->add('Context', 'Key 2', { AddedAt => 1, ThisMeta => 'String2' } ),
  'ContextMeta add 2'
);

ok( 
  $cmeta->add('Context2', 'Key', { AddedAt => 1, Meta => 'String' } ),
  'ContextMeta add new context'
);

is_deeply(
  $cmeta->fetch('Context', 'Key'),
  { AddedAt => 1, ThisMeta => 'String' },
  'Fetch first context/key'
);

is_deeply(
  $cmeta->fetch('Context', 'Key 2'),
  { AddedAt => 1, ThisMeta => 'String2' },
  'Fetch 2nd context/key'
);

is_deeply(
  $cmeta->fetch('Context2', 'Key'),
  { AddedAt => 1, Meta => 'String' },
  'Fetch 3rd context/key'
);

is_deeply(
  scalar $cmeta->list,
  {
    Context => {
      Key => { AddedAt => 1, ThisMeta => 'String' },
      'Key 2' => { AddedAt => 1, ThisMeta => 'String2' },
    },
    
    Context2 => {
      Key => { AddedAt => 1, Meta => 'String' },
    },
  },
  'list() full'
);

is_deeply(
  scalar $cmeta->list('Context2'),
  {
    Key => { AddedAt => 1, Meta => 'String' },
  },
  'list() context'
);

ok( $cmeta->del('Context2', 'Key'), 'Key delete' );

ok( !$cmeta->fetch('Context2', 'Key'), 'Key really deleted' );

ok( $cmeta->clear('Context'), 'Clear context' );

ok( !$cmeta->list('Context'), 'Context really cleared' );
