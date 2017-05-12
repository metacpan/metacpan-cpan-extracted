use utf8;
package Biblio::Zotero::DB::Schema::Result::Highlight;
$Biblio::Zotero::DB::Schema::Result::Highlight::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("highlights");


__PACKAGE__->add_columns(
  "highlightid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "itemid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "startparent",
  { data_type => "text", is_nullable => 1 },
  "starttextnode",
  { data_type => "int", is_nullable => 1 },
  "startoffset",
  { data_type => "int", is_nullable => 1 },
  "endparent",
  { data_type => "text", is_nullable => 1 },
  "endtextnode",
  { data_type => "int", is_nullable => 1 },
  "endoffset",
  { data_type => "int", is_nullable => 1 },
  "datemodified",
  { data_type => "date", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("highlightid");


__PACKAGE__->belongs_to(
  "itemid",
  "Biblio::Zotero::DB::Schema::Result::ItemAttachment",
  { itemid => "itemid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wiTeSJgvG2XgUg9h/KyvkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Highlight

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Highlight

=head1 TABLE: C<highlights>

=head1 ACCESSORS

=head2 highlightid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 itemid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 startparent

  data_type: 'text'
  is_nullable: 1

=head2 starttextnode

  data_type: 'int'
  is_nullable: 1

=head2 startoffset

  data_type: 'int'
  is_nullable: 1

=head2 endparent

  data_type: 'text'
  is_nullable: 1

=head2 endtextnode

  data_type: 'int'
  is_nullable: 1

=head2 endoffset

  data_type: 'int'
  is_nullable: 1

=head2 datemodified

  data_type: 'date'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</highlightid>

=back

=head1 RELATIONS

=head2 itemid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::ItemAttachment>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
