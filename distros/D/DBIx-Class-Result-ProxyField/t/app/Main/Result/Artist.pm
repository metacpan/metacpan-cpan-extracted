package t::app::Main::Result::Artist;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
    "artistid",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    {   data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 255
    });
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many('cds' => 't::app::Main::Result::Cd', 'artistid');

__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->register_relationships_columns_data();
1;
