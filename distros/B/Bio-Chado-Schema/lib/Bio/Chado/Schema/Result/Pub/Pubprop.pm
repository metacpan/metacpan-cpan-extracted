package Bio::Chado::Schema::Result::Pub::Pubprop;
BEGIN {
  $Bio::Chado::Schema::Result::Pub::Pubprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Pub::Pubprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Pub::Pubprop

=head1 DESCRIPTION

Property-value pairs for a pub. Follows standard chado pattern.

=cut

__PACKAGE__->table("pubprop");

=head1 ACCESSORS

=head2 pubprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pubprop_pubprop_id_seq'

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pubprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pubprop_pubprop_id_seq",
  },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
  "rank",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pubprop_id");
__PACKAGE__->add_unique_constraint("pubprop_c1", ["pub_id", "type_id", "rank"]);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g5Q0V9NeXfSTgkYfeQa8mQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
