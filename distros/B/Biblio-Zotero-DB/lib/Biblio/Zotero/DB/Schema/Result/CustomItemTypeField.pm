use utf8;
package Biblio::Zotero::DB::Schema::Result::CustomItemTypeField;
$Biblio::Zotero::DB::Schema::Result::CustomItemTypeField::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("customItemTypeFields");


__PACKAGE__->add_columns(
  "customitemtypeid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "fieldid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 1 },
  "customfieldid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 1 },
  "hide",
  { data_type => "int", is_nullable => 0 },
  "orderindex",
  { data_type => "int", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("customitemtypeid", "orderindex");


__PACKAGE__->belongs_to(
  "customfieldid",
  "Biblio::Zotero::DB::Schema::Result::CustomField",
  { customfieldid => "customfieldid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


__PACKAGE__->belongs_to(
  "customitemtypeid",
  "Biblio::Zotero::DB::Schema::Result::CustomItemType",
  { customitemtypeid => "customitemtypeid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "fieldid",
  "Biblio::Zotero::DB::Schema::Result::Field",
  { fieldid => "fieldid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J7vZwhA6IbKSqu9f0Y6ZMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::CustomItemTypeField

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::CustomItemTypeField

=head1 TABLE: C<customItemTypeFields>

=head1 ACCESSORS

=head2 customitemtypeid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 fieldid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 1

=head2 customfieldid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 1

=head2 hide

  data_type: 'int'
  is_nullable: 0

=head2 orderindex

  data_type: 'int'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</customitemtypeid>

=item * L</orderindex>

=back

=head1 RELATIONS

=head2 customfieldid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::CustomField>

=head2 customitemtypeid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::CustomItemType>

=head2 fieldid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Field>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
