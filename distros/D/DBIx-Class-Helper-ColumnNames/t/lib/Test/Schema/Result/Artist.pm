package Test::Schema::Result::Artist;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw/ artistid name fingers hats teeth /);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many(cds => 'Test::Schema::Result::CD', 'artistid');

1;
