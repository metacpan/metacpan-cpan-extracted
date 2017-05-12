use utf8;
package Biblio::Zotero::DB::Schema::Result::GroupItem;
$Biblio::Zotero::DB::Schema::Result::GroupItem::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("groupItems");


__PACKAGE__->add_columns(
  "itemid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "createdbyuserid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "lastmodifiedbyuserid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
);


__PACKAGE__->set_primary_key("itemid");


__PACKAGE__->belongs_to(
  "createdbyuserid",
  "Biblio::Zotero::DB::Schema::Result::User",
  { userid => "createdbyuserid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "lastmodifiedbyuserid",
  "Biblio::Zotero::DB::Schema::Result::User",
  { userid => "lastmodifiedbyuserid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0amPL6WGSHVitMFRyTmNnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::GroupItem

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::GroupItem

=head1 TABLE: C<groupItems>

=head1 ACCESSORS

=head2 itemid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 createdbyuserid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 lastmodifiedbyuserid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</itemid>

=back

=head1 RELATIONS

=head2 createdbyuserid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::User>

=head2 lastmodifiedbyuserid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::User>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
