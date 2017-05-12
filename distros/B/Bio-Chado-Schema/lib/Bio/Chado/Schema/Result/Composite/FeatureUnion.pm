package Bio::Chado::Schema::Result::Composite::FeatureUnion;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::FeatureUnion::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::FeatureUnion::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::FeatureUnion

=head1 DESCRIPTION

set-union on interval defined by featureloc. featurelocs must meet

=cut

__PACKAGE__->table("feature_union");

=head1 ACCESSORS

=head2 subject_id

  data_type: 'integer'
  is_nullable: 1

=head2 object_id

  data_type: 'integer'
  is_nullable: 1

=head2 srcfeature_id

  data_type: 'integer'
  is_nullable: 1

=head2 subject_strand

  data_type: 'smallint'
  is_nullable: 1

=head2 object_strand

  data_type: 'smallint'
  is_nullable: 1

=head2 fmin

  data_type: 'integer'
  is_nullable: 1

=head2 fmax

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "subject_id",
  { data_type => "integer", is_nullable => 1 },
  "object_id",
  { data_type => "integer", is_nullable => 1 },
  "srcfeature_id",
  { data_type => "integer", is_nullable => 1 },
  "subject_strand",
  { data_type => "smallint", is_nullable => 1 },
  "object_strand",
  { data_type => "smallint", is_nullable => 1 },
  "fmin",
  { data_type => "integer", is_nullable => 1 },
  "fmax",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UYhA7VAUmHlLMUMa04impA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
