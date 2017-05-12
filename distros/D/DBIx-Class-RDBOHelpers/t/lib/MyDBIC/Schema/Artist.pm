package MyDBIC::Schema::Artist;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw/ artistid name /);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->add_unique_constraint( [qw(name)] );
__PACKAGE__->has_many( 'cds' => 'MyDBIC::Schema::Cd' );

1;
