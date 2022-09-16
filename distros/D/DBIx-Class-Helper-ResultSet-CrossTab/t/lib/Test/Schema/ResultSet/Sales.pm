package Test::Schema::ResultSet::Sales;
 
use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw{Helper::ResultSet::CrossTab});
