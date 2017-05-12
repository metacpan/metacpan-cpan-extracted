package Bio::Chado::Schema::Result::Composite::Gff3view;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::Gff3view::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::Gff3view::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::Gff3view

=cut

__PACKAGE__->table("gff3view");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 ref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 fstart

  data_type: 'integer'
  is_nullable: 1

=head2 fend

  data_type: 'integer'
  is_nullable: 1

=head2 score

  data_type: 'text'
  is_nullable: 1

=head2 strand

  data_type: 'text'
  is_nullable: 1

=head2 phase

  data_type: 'text'
  is_nullable: 1

=head2 seqlen

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "ref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "fstart",
  { data_type => "integer", is_nullable => 1 },
  "fend",
  { data_type => "integer", is_nullable => 1 },
  "score",
  { data_type => "text", is_nullable => 1 },
  "strand",
  { data_type => "text", is_nullable => 1 },
  "phase",
  { data_type => "text", is_nullable => 1 },
  "seqlen",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gtyVWR2RHrLWuWOIDDzGWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
