use utf8;
package Biblio::Zotero::DB::Schema::Result::Group;
$Biblio::Zotero::DB::Schema::Result::Group::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("groups");


__PACKAGE__->add_columns(
  "groupid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "libraryid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "editable",
  { data_type => "int", is_nullable => 0 },
  "fileseditable",
  { data_type => "int", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("groupid");


__PACKAGE__->add_unique_constraint("libraryid_unique", ["libraryid"]);


__PACKAGE__->belongs_to(
  "libraryid",
  "Biblio::Zotero::DB::Schema::Result::Library",
  { libraryid => "libraryid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rM5kHMX8OVtOSssn89CDlQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Group

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Group

=head1 TABLE: C<groups>

=head1 ACCESSORS

=head2 groupid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 libraryid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 editable

  data_type: 'int'
  is_nullable: 0

=head2 fileseditable

  data_type: 'int'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</groupid>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<libraryid_unique>

=over 4

=item * L</libraryid>

=back

=head1 RELATIONS

=head2 libraryid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Library>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
