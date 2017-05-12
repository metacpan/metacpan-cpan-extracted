package TestSchema::Result::Role;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table("role");

__PACKAGE__->add_columns(
    "id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "user", { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "name", { data_type => "varchar", is_nullable => 0, size => 40 }
);    
__PACKAGE__->set_primary_key(qw(id));

__PACKAGE__->belongs_to("user", 'TestSchema::Result::User', {id => "user"});

__PACKAGE__->has_many(
    "permissions",
    'TestSchema::Result::Permission',
    { "foreign.role" => "self.id" }
);    


1;
