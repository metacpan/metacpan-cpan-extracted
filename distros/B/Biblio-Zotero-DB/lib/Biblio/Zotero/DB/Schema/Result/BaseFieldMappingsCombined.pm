use utf8;
package Biblio::Zotero::DB::Schema::Result::BaseFieldMappingsCombined;
$Biblio::Zotero::DB::Schema::Result::BaseFieldMappingsCombined::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("baseFieldMappingsCombined");


__PACKAGE__->add_columns(
  "itemtypeid",
  { data_type => "int", is_nullable => 0 },
  "basefieldid",
  { data_type => "int", is_nullable => 0 },
  "fieldid",
  { data_type => "int", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("itemtypeid", "basefieldid", "fieldid");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6B6yT2r2p8qUcBXB1GQ4gA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::BaseFieldMappingsCombined

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::BaseFieldMappingsCombined

=head1 TABLE: C<baseFieldMappingsCombined>

=head1 ACCESSORS

=head2 itemtypeid

  data_type: 'int'
  is_nullable: 0

=head2 basefieldid

  data_type: 'int'
  is_nullable: 0

=head2 fieldid

  data_type: 'int'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</itemtypeid>

=item * L</basefieldid>

=item * L</fieldid>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
