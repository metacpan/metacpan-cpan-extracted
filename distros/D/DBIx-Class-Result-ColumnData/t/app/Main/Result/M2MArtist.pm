package t::app::Main::Result::M2MArtist;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw/ artistid name /);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many('cds' => 't::app::Main::Result::Cd', 'artistid');

__PACKAGE__->load_components(qw/ IntrospectableM2M Result::ColumnData /);
__PACKAGE__->register_relationships_column_data();
1;
