package t::app::Main::Result::M2MCdsM2MArtist;
use base qw/DBIx::Class::Core/;
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('cds_artists');
__PACKAGE__->add_columns('cdid',
                         {data_type => 'integer'},
                         'artistid',
                         {data_type => 'integer'},
                       );
__PACKAGE__->belongs_to('m2martist' => 't::app::Main::Result::M2MArtist', 'artistid');
__PACKAGE__->belongs_to('m2mcd' => 't::app::Main::Result::M2MCd', 'cdid');

__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->register_relationships_column_data();
1;
