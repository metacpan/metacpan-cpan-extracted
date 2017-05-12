package Schema::RBAC::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 active

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "active",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<Schema::RBAC::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Schema::RBAC::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-02 18:58:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t8+TJh3PCELqA9wj7MjzXg

__PACKAGE__->add_columns(
    "password",
    {
        data_type                                   => "CHAR",
        is_nullable                                 => 0,
        size                                        => 40,
        encode_column                               => 1,
        encode_class                                => 'Digest',
        encode_args                                 => { algorithm => 'SHA-1', format => 'hex' },
        encode_check_method                         => 'check_password',
    },
);


__PACKAGE__->add_columns(
    "created" => { data_type => 'timestamp', set_on_create => 1, is_nullable => 0, },
);


__PACKAGE__->many_to_many( roles => 'user_roles', 'role',);

__PACKAGE__->has_many(
  "user_roles",
  "Schema::RBAC::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


sub roles{
  my $self = shift;
  $self->roles->search({ active => 1});
}



# Return all user permissions
sub permissions {
  my $self = shift;

   my @perms;
   foreach my $r ( $self->roles ){
     push(@perms, map{ $_->name } $r->permissions );
   }

   return @perms;
}

# check if the authenticated user has the specified role
sub asa {
  my ( $self, $role ) = @_;

  if ($role) {
    if (grep { /$role/ } map { $_->name } @{$self->roles}) {
      return 1;
    }
  }

  return 0;
}


# # check if the authenticated user has permission
# sub can {
#   my ( $self, $perm ) = @_;

#   if ($perm) {
#     if (grep { /$perm/ } @{$self->permissions}) {
#       return 1;
#     }
#   }

#   return 0;
# }


1;
