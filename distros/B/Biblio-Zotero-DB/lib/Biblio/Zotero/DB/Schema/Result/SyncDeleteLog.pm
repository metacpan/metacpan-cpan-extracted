use utf8;
package Biblio::Zotero::DB::Schema::Result::SyncDeleteLog;
$Biblio::Zotero::DB::Schema::Result::SyncDeleteLog::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("syncDeleteLog");


__PACKAGE__->add_columns(
  "syncobjecttypeid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "libraryid",
  { data_type => "int", is_nullable => 0 },
  "key",
  { data_type => "text", is_nullable => 0 },
  "timestamp",
  { data_type => "int", is_nullable => 0 },
);


__PACKAGE__->add_unique_constraint(
  "syncobjecttypeid_libraryid_key_unique",
  ["syncobjecttypeid", "libraryid", "key"],
);


__PACKAGE__->belongs_to(
  "syncobjecttypeid",
  "Biblio::Zotero::DB::Schema::Result::SyncObjectType",
  { syncobjecttypeid => "syncobjecttypeid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SbV7iU/RXaLVEvgMh4sQcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SyncDeleteLog

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SyncDeleteLog

=head1 TABLE: C<syncDeleteLog>

=head1 ACCESSORS

=head2 syncobjecttypeid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 libraryid

  data_type: 'int'
  is_nullable: 0

=head2 key

  data_type: 'text'
  is_nullable: 0

=head2 timestamp

  data_type: 'int'
  is_nullable: 0

=head1 UNIQUE CONSTRAINTS

=head2 C<syncobjecttypeid_libraryid_key_unique>

=over 4

=item * L</syncobjecttypeid>

=item * L</libraryid>

=item * L</key>

=back

=head1 RELATIONS

=head2 syncobjecttypeid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::SyncObjectType>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
