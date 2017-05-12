use utf8;
package Biblio::Zotero::DB::Schema::Result::ItemData;
$Biblio::Zotero::DB::Schema::Result::ItemData::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("itemData");


__PACKAGE__->add_columns(
  "itemid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "fieldid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "valueid",
  { data_type => "", is_foreign_key => 1, is_nullable => 1 },
);


__PACKAGE__->set_primary_key("itemid", "fieldid");


__PACKAGE__->belongs_to(
  "fieldid",
  "Biblio::Zotero::DB::Schema::Result::Field",
  { fieldid => "fieldid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "itemid",
  "Biblio::Zotero::DB::Schema::Result::Item",
  { itemid => "itemid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "valueid",
  "Biblio::Zotero::DB::Schema::Result::ItemDataValue",
  { valueid => "valueid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:roFvJq1zvhoDYyltiT55LQ

# NOTE: extended DBIC schema below


# TODO: document
sub field_value {
	my ($self) = @_;
	return $self->fieldid->fieldname => $self->valueid->value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemData

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemData

=head1 TABLE: C<itemData>

=head1 ACCESSORS

=head2 itemid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 fieldid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 valueid

  data_type: (empty string)
  is_foreign_key: 1
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</itemid>

=item * L</fieldid>

=back

=head1 RELATIONS

=head2 fieldid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Field>

=head2 itemid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Item>

=head2 valueid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemDataValue>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
