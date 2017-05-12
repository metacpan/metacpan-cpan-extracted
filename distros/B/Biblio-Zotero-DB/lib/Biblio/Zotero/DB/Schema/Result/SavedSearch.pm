use utf8;
package Biblio::Zotero::DB::Schema::Result::SavedSearch;
$Biblio::Zotero::DB::Schema::Result::SavedSearch::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("savedSearches");


__PACKAGE__->add_columns(
  "savedsearchid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "savedsearchname",
  { data_type => "text", is_nullable => 0 },
  "dateadded",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "datemodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "clientdatemodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "libraryid",
  { data_type => "int", is_nullable => 1 },
  "key",
  { data_type => "text", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("savedsearchid");


__PACKAGE__->add_unique_constraint("libraryid_key_unique", ["libraryid", "key"]);


__PACKAGE__->has_many(
  "saved_search_conditions",
  "Biblio::Zotero::DB::Schema::Result::SavedSearchCondition",
  { "foreign.savedsearchid" => "self.savedsearchid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tBpgaZNfOkTpszoJb8m94Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SavedSearch

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SavedSearch

=head1 TABLE: C<savedSearches>

=head1 ACCESSORS

=head2 savedsearchid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 savedsearchname

  data_type: 'text'
  is_nullable: 0

=head2 dateadded

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 datemodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 clientdatemodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 libraryid

  data_type: 'int'
  is_nullable: 1

=head2 key

  data_type: 'text'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</savedsearchid>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<libraryid_key_unique>

=over 4

=item * L</libraryid>

=item * L</key>

=back

=head1 RELATIONS

=head2 saved_search_conditions

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::SavedSearchCondition>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
