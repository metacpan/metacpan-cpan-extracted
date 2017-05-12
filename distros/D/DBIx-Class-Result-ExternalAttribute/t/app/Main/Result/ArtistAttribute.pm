package t::app::Main::Result::ArtistAttribute;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('artist_attribute');
__PACKAGE__->add_columns(
    "artist_id",
    { data_type => "integer", is_nullable => 0 },
    "year_old",
    { data_type     => "integer", is_nullable   => 1});
__PACKAGE__->set_primary_key('artist_id');
__PACKAGE__->load_components(qw/ Result::ColumnData /);
__PACKAGE__->belongs_to( artist => "t::app::Main::Result::Artist", 'artist_id');

1;
