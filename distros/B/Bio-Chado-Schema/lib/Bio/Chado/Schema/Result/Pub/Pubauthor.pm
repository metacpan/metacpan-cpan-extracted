package Bio::Chado::Schema::Result::Pub::Pubauthor;
BEGIN {
  $Bio::Chado::Schema::Result::Pub::Pubauthor::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Pub::Pubauthor::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Pub::Pubauthor

=head1 DESCRIPTION

An author for a publication. Note the denormalisation (hence lack of _ in table name) - this is deliberate as it is in general too hard to assign IDs to authors.

=cut

__PACKAGE__->table("pubauthor");

=head1 ACCESSORS

=head2 pubauthor_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pubauthor_pubauthor_id_seq'

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  is_nullable: 0

Order of author in author list for this pub - order is important.

=head2 editor

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

Indicates whether the author is an editor for linked publication. Note: this is a boolean field but does not follow the normal chado convention for naming booleans.

=head2 surname

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 givennames

  data_type: 'varchar'
  is_nullable: 1
  size: 100

First name, initials

=head2 suffix

  data_type: 'varchar'
  is_nullable: 1
  size: 100

Jr., Sr., etc

=cut

__PACKAGE__->add_columns(
  "pubauthor_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pubauthor_pubauthor_id_seq",
  },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
  "editor",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "surname",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "givennames",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "suffix",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("pubauthor_id");
__PACKAGE__->add_unique_constraint("pubauthor_c1", ["pub_id", "rank"]);

=head1 RELATIONS

=head2 pub

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "pub_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjWjIT569rVLbnuwk7M7XA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
