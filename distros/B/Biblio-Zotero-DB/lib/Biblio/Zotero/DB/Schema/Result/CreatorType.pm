use utf8;
package Biblio::Zotero::DB::Schema::Result::CreatorType;
$Biblio::Zotero::DB::Schema::Result::CreatorType::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("creatorTypes");


__PACKAGE__->add_columns(
  "creatortypeid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "creatortype",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("creatortypeid");


__PACKAGE__->has_many(
  "item_creators",
  "Biblio::Zotero::DB::Schema::Result::ItemCreator",
  { "foreign.creatortypeid" => "self.creatortypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "item_type_creator_types",
  "Biblio::Zotero::DB::Schema::Result::ItemTypeCreatorType",
  { "foreign.creatortypeid" => "self.creatortypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SWeXs7jA21XVReAIWrm9Eg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::CreatorType

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::CreatorType

=head1 TABLE: C<creatorTypes>

=head1 ACCESSORS

=head2 creatortypeid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 creatortype

  data_type: 'text'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</creatortypeid>

=back

=head1 RELATIONS

=head2 item_creators

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemCreator>

=head2 item_type_creator_types

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemTypeCreatorType>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
