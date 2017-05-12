use utf8;
package Schema::RBAC::Result::Comment;

=head1 NAME

Schema::TPath::Result::Comment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->load_components;
__PACKAGE__->table("comments");
__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "INTEGER",
        is_nullable       => 0,
        size              => undef,
        is_auto_increment => 1
    },
    "page_id",
    { data_type => "INTEGER", is_nullable => 0, size => undef },
    "body",
    { data_type => "TEXT", is_nullable => 0, size => undef },
    "active",
    { data_type => "tinyint", default_value => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "page",
    "Schema::RBAC::Result::Page",
    { "foreign.id" => "self.page_id" }
);


__PACKAGE__->has_many(
  "obj_operations",
  "Schema::RBAC::Result::ObjOperation",
  { "foreign.obj_id"     => "self.id" },
  {  where => { typeobj_id => 3 }},
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( ops_to_access => 'obj_operations', 'operation',);


=head1 NAME

Schema::RBAC::Result::Comment - store comments

=head1 METHODS


=head1 AUTHOR

Daniel Brosseau <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
