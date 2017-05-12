  package DBICT::Result::Test;
  use base qw/DBIx::Class/;

  __PACKAGE__->load_components(qw/Core/);
  __PACKAGE__->table('Test');
__PACKAGE__->add_columns(qw/id description/);
__PACKAGE__->set_primary_key('id');

1;
