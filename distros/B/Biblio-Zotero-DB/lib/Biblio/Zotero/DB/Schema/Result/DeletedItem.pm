use utf8;
package Biblio::Zotero::DB::Schema::Result::DeletedItem;
$Biblio::Zotero::DB::Schema::Result::DeletedItem::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("deletedItems");


__PACKAGE__->add_columns(
  "itemid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "datedeleted",
  {
    data_type     => "",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);


__PACKAGE__->set_primary_key("itemid");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/tamvXs5KkDISkgxH9iZQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::DeletedItem

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::DeletedItem

=head1 TABLE: C<deletedItems>

=head1 ACCESSORS

=head2 itemid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 datedeleted

  data_type: (empty string)
  default_value: current_timestamp
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</itemid>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
