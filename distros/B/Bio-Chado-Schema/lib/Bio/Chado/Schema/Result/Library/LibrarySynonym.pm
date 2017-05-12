package Bio::Chado::Schema::Result::Library::LibrarySynonym;
BEGIN {
  $Bio::Chado::Schema::Result::Library::LibrarySynonym::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Library::LibrarySynonym::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Library::LibrarySynonym

=cut

__PACKAGE__->table("library_synonym");

=head1 ACCESSORS

=head2 library_synonym_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_synonym_library_synonym_id_seq'

=head2 synonym_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The pub_id link is for
relating the usage of a given synonym to the publication in which it was used.

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

The is_current bit indicates whether the linked synonym is the current -official- symbol for the linked library.

=head2 is_internal

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

Typically a synonym
exists so that somebody querying the database with an obsolete name
can find the object they are looking for under its current name.  If
the synonym has been used publicly and deliberately (e.g. in a paper), it my also be listed in reports as a synonym.   If the synonym was not used deliberately (e.g., there was a typo which went public), then the is_internal bit may be set to "true" so that it is known that the synonym is "internal" and should be queryable but should not be listed in reports as a valid synonym.

=cut

__PACKAGE__->add_columns(
  "library_synonym_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_synonym_library_synonym_id_seq",
  },
  "synonym_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "is_internal",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("library_synonym_id");
__PACKAGE__->add_unique_constraint("library_synonym_c1", ["synonym_id", "library_id", "pub_id"]);

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

=head2 synonym

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Synonym>

=cut

__PACKAGE__->belongs_to(
  "synonym",
  "Bio::Chado::Schema::Result::Sequence::Synonym",
  { synonym_id => "synonym_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xgRXrLhsUuPfjabjNYc08A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
