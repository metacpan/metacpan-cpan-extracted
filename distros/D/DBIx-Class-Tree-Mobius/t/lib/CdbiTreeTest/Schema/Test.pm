package # hide from PAUSE
    CdbiTreeTest::Schema::Test;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Tree::Mobius Core /);
__PACKAGE__->table('test');

__PACKAGE__->add_columns(
  id => { data_type => 'INT', is_nullable => 0, is_auto_increment => 1 },
  data => { data_type => 'VARCHAR', size => 255 },
);

__PACKAGE__->add_mobius_tree_columns(
    mobius_a => 'a',
    mobius_b => 'b',
    mobius_c => 'c',
    mobius_d => 'd',
    );

__PACKAGE__->set_primary_key('id');

__PACKAGE__->strict_mode( 0 );

1;
