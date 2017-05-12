package Bio::Chado::Schema::Result::Cv::Chadoprop;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::Chadoprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::Chadoprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::Chadoprop

=head1 DESCRIPTION

This table is different from other prop tables in the database, as it is for storing information about the database itself, like schema version

=cut

__PACKAGE__->table("chadoprop");

=head1 ACCESSORS

=head2 chadoprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'chadoprop_chadoprop_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the property or slot is a cvterm. The meaning of the property is defined in that cvterm.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the property, represented as text. Numeric values are converted to their text representation.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Property-Value ordering. Any
cv can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used.

=cut

__PACKAGE__->add_columns(
  "chadoprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chadoprop_chadoprop_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("chadoprop_id");
__PACKAGE__->add_unique_constraint("chadoprop_c1", ["type_id", "rank"]);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-22 08:45:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zh5iGr+9B0FCmXj6pNcyTA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
