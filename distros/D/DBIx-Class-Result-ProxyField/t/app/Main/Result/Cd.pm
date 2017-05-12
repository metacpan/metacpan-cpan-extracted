package t::app::Main::Result::Cd;
use base qw/DBIx::Class::Core/;
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns('cdid',
                         { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
                         'artistid',
                         {data_type => 'integer', is_nullable => 0},
                         'title',
                         {data_type => 'varchar', is_nullable => 0},
                         'date',
                         {data_type => 'date', is_nullable => 1},
                         'last_listen',
                         {data_type => 'datetime', is_nullable => 1},
                       );
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to('artist' => 't::app::Main::Result::Artist', 'artistid');
__PACKAGE__->has_many('tracks' => 't::app::Main::Result::Track', 'cdid');

__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->register_relationships_columns_data();
1;
