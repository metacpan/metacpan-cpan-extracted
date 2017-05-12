use utf8;
package Biblio::Zotero::DB::Schema::Result::ItemType;
$Biblio::Zotero::DB::Schema::Result::ItemType::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("itemTypes");


__PACKAGE__->add_columns(
  "itemtypeid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "typename",
  { data_type => "text", is_nullable => 1 },
  "templateitemtypeid",
  { data_type => "int", is_nullable => 1 },
  "display",
  { data_type => "int", default_value => 1, is_nullable => 1 },
);


__PACKAGE__->set_primary_key("itemtypeid");


__PACKAGE__->has_many(
  "base_field_mappings",
  "Biblio::Zotero::DB::Schema::Result::BaseFieldMapping",
  { "foreign.itemtypeid" => "self.itemtypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "item_type_creator_types",
  "Biblio::Zotero::DB::Schema::Result::ItemTypeCreatorType",
  { "foreign.itemtypeid" => "self.itemtypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "item_type_fields",
  "Biblio::Zotero::DB::Schema::Result::ItemTypeField",
  { "foreign.itemtypeid" => "self.itemtypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9neWrGI+M7r0VExseuNPPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemType

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemType

=head1 TABLE: C<itemTypes>

=head1 ACCESSORS

=head2 itemtypeid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 typename

  data_type: 'text'
  is_nullable: 1

=head2 templateitemtypeid

  data_type: 'int'
  is_nullable: 1

=head2 display

  data_type: 'int'
  default_value: 1
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</itemtypeid>

=back

=head1 RELATIONS

=head2 base_field_mappings

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::BaseFieldMapping>

=head2 item_type_creator_types

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemTypeCreatorType>

=head2 item_type_fields

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemTypeField>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
