package Bio::Chado::Schema::Result::Project::ProjectContact;
BEGIN {
  $Bio::Chado::Schema::Result::Project::ProjectContact::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Project::ProjectContact::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Project::ProjectContact - Linking table for associating projects and contacts.

=cut

__PACKAGE__->table("project_contact");

=head1 ACCESSORS

=head2 project_contact_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_contact_project_contact_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project_contact_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_contact_project_contact_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("project_contact_id");
__PACKAGE__->add_unique_constraint("project_contact_c1", ["project_id", "contact_id"]);

=head1 RELATIONS

=head2 project

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Project::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Bio::Chado::Schema::Result::Project::Project",
  { project_id => "project_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 contact

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "contact_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-06 11:44:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YB1GZ0y1aOcXf5xRM0ueGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
