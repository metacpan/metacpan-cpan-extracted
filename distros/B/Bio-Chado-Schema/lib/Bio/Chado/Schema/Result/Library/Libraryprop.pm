package Bio::Chado::Schema::Result::Library::Libraryprop;
BEGIN {
  $Bio::Chado::Schema::Result::Library::Libraryprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Library::Libraryprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Library::Libraryprop

=cut

__PACKAGE__->table("libraryprop");

=head1 ACCESSORS

=head2 libraryprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'libraryprop_libraryprop_id_seq'

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "libraryprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "libraryprop_libraryprop_id_seq",
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("libraryprop_id");
__PACKAGE__->add_unique_constraint("libraryprop_c1", ["library_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 type

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "type_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 library

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Library::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Bio::Chado::Schema::Result::Library::Library",
  { library_id => "library_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 libraryprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibrarypropPub>

=cut

__PACKAGE__->has_many(
  "libraryprop_pubs",
  "Bio::Chado::Schema::Result::Library::LibrarypropPub",
  { "foreign.libraryprop_id" => "self.libraryprop_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4hf4DjJSFGhNEISlMvxVJA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
