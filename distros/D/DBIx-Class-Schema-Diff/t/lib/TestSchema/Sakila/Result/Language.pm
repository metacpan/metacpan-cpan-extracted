package # Hide from pause
     TestSchema::Sakila::Result::Language;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila::Result::Language

=cut

__PACKAGE__->table("language");

=head1 ACCESSORS

=head2 language_id

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 20

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "language_id",
  {
    data_type => "tinyint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 20 },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("language_id");

=head1 RELATIONS

=head2 film_languages

Type: has_many

Related object: L<TestSchema::Sakila::Result::Film>

=cut

__PACKAGE__->has_many(
  "film_languages",
  "TestSchema::Sakila::Result::Film",
  { "foreign.language_id" => "self.language_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 film_original_languages

Type: has_many

Related object: L<TestSchema::Sakila::Result::Film>

=cut

__PACKAGE__->has_many(
  "film_original_languages",
  "TestSchema::Sakila::Result::Film",
  { "foreign.original_language_id" => "self.language_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JK+DOUbIw1Lhrmp6PE2Q4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
