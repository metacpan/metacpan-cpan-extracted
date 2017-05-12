package t::app::Main::Result::Track;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('track');
__PACKAGE__->add_columns('trackid',
                         { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
                         'cdid',
                         {data_type => 'integer', is_nullable => 0},
                         'title',
                         {data_type => 'varchar', is_nullable => 0});
__PACKAGE__->set_primary_key('trackid');
__PACKAGE__->belongs_to('cd' => 't::app::Main::Result::Cd', 'cdid');

__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->register_relationships_column_data();
1;
