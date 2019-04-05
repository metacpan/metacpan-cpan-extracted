package Test::Schema::ResultSet::Artist;


use base qw/DBIx::Class::ResultSet/;

__PACKAGE__->load_components('Helper::SimpleStats');

1;
