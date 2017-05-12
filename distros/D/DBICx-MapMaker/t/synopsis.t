use strict;
use warnings;
use Test::More tests => 16;
use DBICx::TestDatabase;
use ok 'DBICx::MapMaker';

{ package MySchema::A;
  use base 'DBIx::Class';
  __PACKAGE__->load_components('Core');
  __PACKAGE__->table('a');
  __PACKAGE__->add_columns(
      id  => { data_type => 'INTEGER', is_auto_increment => 1 },
      foo => { data_type => 'TEXT' },
  );
  __PACKAGE__->set_primary_key('id');

  package MySchema::B;
  use base 'DBIx::Class';
  __PACKAGE__->load_components('Core');
  __PACKAGE__->table('b');
  __PACKAGE__->add_columns(
      id  => { data_type => 'INTEGER', is_auto_increment => 1 },
      foo => { data_type => 'TEXT' },
  );
  __PACKAGE__->set_primary_key('id');

  package MySchema::MapAB;
  use DBICx::MapMaker;
  use base 'DBIx::Class';
  
  my $map = DBICx::MapMaker->new(
      left_class  => 'MySchema::A',
      right_class => 'MySchema::B',
  
      left_name   => 'a',
      right_name  => 'b',
  );
    
  $map->setup_table(__PACKAGE__);

  package MySchema;
  use strict;
  use warnings;
  use base 'DBIx::Class::Schema';
  __PACKAGE__->load_classes(qw/A B MapAB/);
}

$INC{'MySchema.pm'} = 1;

my $schema = DBICx::TestDatabase->new('MySchema');
ok $schema, 'deployed db ok';

$schema->resultset('A')->create({ foo => 'a1' });
$schema->resultset('B')->create({ foo => 'b1' });
$schema->resultset('MapAB')->create({ a => 1, b => 1 });

my $a = $schema->resultset('A')->find(1);
ok $a;
ok $a->b_map;
ok $a->bs;
is $a->b_map->count, '1';
is [$a->bs]->[0]->foo, 'b1';
is $a->column_info('id')->{'is_auto_increment'}, 1;

my $b = $schema->resultset('B')->find(1);
ok $b;
ok $b->a_map;
ok $b->as;
is $b->a_map->count, '1';
is [$b->as]->[0]->foo, 'a1';
is $b->column_info('id')->{'is_auto_increment'}, 1;

my $map = $schema->resultset('MapAB')->find({ a => 1, b => 1 });
isnt $map->column_info('a')->{'is_auto_increment'}, 1;
isnt $map->column_info('b')->{'is_auto_increment'}, 1;
