use utf8;
package Biblio::Zotero::DB::Schema::Result::Annotation;
$Biblio::Zotero::DB::Schema::Result::Annotation::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("annotations");


__PACKAGE__->add_columns(
  "annotationid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "itemid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 1 },
  "parent",
  { data_type => "text", is_nullable => 1 },
  "textnode",
  { data_type => "int", is_nullable => 1 },
  "offset",
  { data_type => "int", is_nullable => 1 },
  "x",
  { data_type => "int", is_nullable => 1 },
  "y",
  { data_type => "int", is_nullable => 1 },
  "cols",
  { data_type => "int", is_nullable => 1 },
  "rows",
  { data_type => "int", is_nullable => 1 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "collapsed",
  { data_type => "bool", is_nullable => 1 },
  "datemodified",
  { data_type => "date", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("annotationid");


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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bkpihzjbzbkl4nEfJIEVsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Annotation

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Annotation

=head1 TABLE: C<annotations>

=head1 ACCESSORS

=head2 annotationid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 itemid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 1

=head2 parent

  data_type: 'text'
  is_nullable: 1

=head2 textnode

  data_type: 'int'
  is_nullable: 1

=head2 offset

  data_type: 'int'
  is_nullable: 1

=head2 x

  data_type: 'int'
  is_nullable: 1

=head2 y

  data_type: 'int'
  is_nullable: 1

=head2 cols

  data_type: 'int'
  is_nullable: 1

=head2 rows

  data_type: 'int'
  is_nullable: 1

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 collapsed

  data_type: 'bool'
  is_nullable: 1

=head2 datemodified

  data_type: 'date'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</annotationid>

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
