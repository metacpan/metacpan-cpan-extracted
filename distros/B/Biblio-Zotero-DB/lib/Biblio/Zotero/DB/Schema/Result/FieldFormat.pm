use utf8;
package Biblio::Zotero::DB::Schema::Result::FieldFormat;
$Biblio::Zotero::DB::Schema::Result::FieldFormat::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("fieldFormats");


__PACKAGE__->add_columns(
  "fieldformatid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "regex",
  { data_type => "text", is_nullable => 1 },
  "isinteger",
  { data_type => "int", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("fieldformatid");


__PACKAGE__->has_many(
  "fields",
  "Biblio::Zotero::DB::Schema::Result::Field",
  { "foreign.fieldformatid" => "self.fieldformatid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mqu1YGxo4zvHNv3IEEOadA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::FieldFormat

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::FieldFormat

=head1 TABLE: C<fieldFormats>

=head1 ACCESSORS

=head2 fieldformatid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 regex

  data_type: 'text'
  is_nullable: 1

=head2 isinteger

  data_type: 'int'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</fieldformatid>

=back

=head1 RELATIONS

=head2 fields

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::Field>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
