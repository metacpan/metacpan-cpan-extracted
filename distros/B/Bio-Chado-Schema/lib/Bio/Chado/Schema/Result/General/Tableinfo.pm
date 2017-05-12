package Bio::Chado::Schema::Result::General::Tableinfo;
BEGIN {
  $Bio::Chado::Schema::Result::General::Tableinfo::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::General::Tableinfo::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::General::Tableinfo

=cut

__PACKAGE__->table("tableinfo");

=head1 ACCESSORS

=head2 tableinfo_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tableinfo_tableinfo_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 primary_key_column

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 is_view

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 view_on_table_id

  data_type: 'integer'
  is_nullable: 1

=head2 superclass_table_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_updateable

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 modification_date

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "tableinfo_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tableinfo_tableinfo_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "primary_key_column",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "is_view",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "view_on_table_id",
  { data_type => "integer", is_nullable => 1 },
  "superclass_table_id",
  { data_type => "integer", is_nullable => 1 },
  "is_updateable",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "modification_date",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("tableinfo_id");
__PACKAGE__->add_unique_constraint("tableinfo_c1", ["name"]);

=head1 RELATIONS

=head2 controls

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Bio::Chado::Schema::Result::Mage::Control",
  { "foreign.tableinfo_id" => "self.tableinfo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 magedocumentations

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Magedocumentation>

=cut

__PACKAGE__->has_many(
  "magedocumentations",
  "Bio::Chado::Schema::Result::Mage::Magedocumentation",
  { "foreign.tableinfo_id" => "self.tableinfo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j6QlFrHYGpvD1MStkARg1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
