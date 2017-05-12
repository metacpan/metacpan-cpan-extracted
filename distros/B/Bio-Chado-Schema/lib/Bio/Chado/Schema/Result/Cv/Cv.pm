package Bio::Chado::Schema::Result::Cv::Cv;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::Cv::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::Cv::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::Cv

=head1 DESCRIPTION

A controlled vocabulary or ontology. A cv is
composed of cvterms (AKA terms, classes, types, universals - relations
and properties are also stored in cvterm) and the relationships
between them.

=cut

__PACKAGE__->table("cv");

=head1 ACCESSORS

=head2 cv_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cv_cv_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

The name of the ontology. This
corresponds to the obo-format -namespace-. cv names uniquely identify
the cv. In OBO file format, the cv.name is known as the namespace.

=head2 definition

  data_type: 'text'
  is_nullable: 1

A text description of the criteria for
membership of this ontology.

=cut

__PACKAGE__->add_columns(
  "cv_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cv_cv_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "definition",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cv_id");
__PACKAGE__->add_unique_constraint("cv_c1", ["name"]);

=head1 RELATIONS

=head2 cvprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvprop>

=cut

__PACKAGE__->has_many(
  "cvprops",
  "Bio::Chado::Schema::Result::Cv::Cvprop",
  { "foreign.cv_id" => "self.cv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->has_many(
  "cvterms",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { "foreign.cv_id" => "self.cv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpaths

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpaths",
  "Bio::Chado::Schema::Result::Cv::Cvtermpath",
  { "foreign.cv_id" => "self.cv_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:23TTY2CmFJAGprWQlkYWcQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
