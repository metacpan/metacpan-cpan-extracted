use utf8;
package Biblio::Zotero::DB::Schema::Result::SyncObjectType;
$Biblio::Zotero::DB::Schema::Result::SyncObjectType::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("syncObjectTypes");


__PACKAGE__->add_columns(
  "syncobjecttypeid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("syncobjecttypeid");


__PACKAGE__->has_many(
  "sync_delete_logs",
  "Biblio::Zotero::DB::Schema::Result::SyncDeleteLog",
  { "foreign.syncobjecttypeid" => "self.syncobjecttypeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XdxxGgZFy8Y3LjNPjrXAgw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SyncObjectType

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SyncObjectType

=head1 TABLE: C<syncObjectTypes>

=head1 ACCESSORS

=head2 syncobjecttypeid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</syncobjecttypeid>

=back

=head1 RELATIONS

=head2 sync_delete_logs

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::SyncDeleteLog>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
