package t::app::Main::Result::M2MCd;
use base qw/DBIx::Class::Core/;
__PACKAGE__->load_components(qw/InflateColumn::DateTime IntrospectableM2M/);
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
__PACKAGE__->has_many('m2mcds_m2martists' => 't::app::Main::Result::M2MCdsM2MArtist', 'cdid');
__PACKAGE__->many_to_many('m2martists' => 'm2mcds_m2martists', 'm2martist');

__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->register_relationships_column_data();
1;
