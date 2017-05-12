package AuditTestRel::Schema::Result::Person;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('AuditLog');

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    {   data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 32
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints( 'name', ['name'] );

__PACKAGE__->has_many( "bookauthors",
    "AuditTestRel::Schema::Result::BookAuthor", 'author_id' );

__PACKAGE__->many_to_many( 'books', 'bookauthors', 'books' );

1;
