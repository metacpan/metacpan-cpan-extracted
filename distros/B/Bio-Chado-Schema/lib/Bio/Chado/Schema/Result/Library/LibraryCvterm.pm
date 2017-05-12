package Bio::Chado::Schema::Result::Library::LibraryCvterm;
BEGIN {
  $Bio::Chado::Schema::Result::Library::LibraryCvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Library::LibraryCvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Library::LibraryCvterm

=head1 DESCRIPTION

The table library_cvterm links a library to controlled vocabularies which describe the library.  For instance, there might be a link to the anatomy cv for "head" or "testes" for a head or testes library.

=cut

__PACKAGE__->table("library_cvterm");

=head1 ACCESSORS

=head2 library_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_cvterm_library_cvterm_id_seq'

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "library_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_cvterm_library_cvterm_id_seq",
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("library_cvterm_id");
__PACKAGE__->add_unique_constraint("library_cvterm_c1", ["library_id", "cvterm_id", "pub_id"]);

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

=head2 cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvterm_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w26HMpOZWu5YnAvI648PDw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
