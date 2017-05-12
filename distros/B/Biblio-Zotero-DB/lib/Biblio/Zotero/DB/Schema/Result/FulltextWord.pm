use utf8;
package Biblio::Zotero::DB::Schema::Result::FulltextWord;
$Biblio::Zotero::DB::Schema::Result::FulltextWord::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("fulltextWords");


__PACKAGE__->add_columns(
  "wordid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "word",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("wordid");


__PACKAGE__->add_unique_constraint("word_unique", ["word"]);


__PACKAGE__->has_many(
  "fulltext_item_words",
  "Biblio::Zotero::DB::Schema::Result::FulltextItemWord",
  { "foreign.wordid" => "self.wordid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->many_to_many("itemids", "fulltext_item_words", "itemid");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oNp29KcfqOGdexKYtNygew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::FulltextWord

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::FulltextWord

=head1 TABLE: C<fulltextWords>

=head1 ACCESSORS

=head2 wordid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 word

  data_type: 'text'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</wordid>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<word_unique>

=over 4

=item * L</word>

=back

=head1 RELATIONS

=head2 fulltext_item_words

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::FulltextItemWord>

=head2 itemids

Type: many_to_many

Composing rels: L</fulltext_item_words> -> itemid

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
