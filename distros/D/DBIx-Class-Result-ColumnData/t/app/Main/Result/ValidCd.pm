package t::app::Main::Result::ValidCd;
use base qw/DBIx::Class::Core/;
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns('cdid',
                         {data_type => 'integer'},
                         'artistid',
                         {data_type => 'integer'},
                         'title',
                         {data_type => 'varchar'},
                         'date',
                         {data_type => 'date'},
                         'last_listen',
                         {data_type => 'datetime'},
                       );
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to('artist' => 't::app::Main::Result::Artist', 'artistid');
__PACKAGE__->has_many('tracks' => 't::app::Main::Result::Track', 'cdid');

__PACKAGE__->load_components(qw/ Result::ColumnData Result::Validation/);
__PACKAGE__->register_relationships_column_data();
1;
