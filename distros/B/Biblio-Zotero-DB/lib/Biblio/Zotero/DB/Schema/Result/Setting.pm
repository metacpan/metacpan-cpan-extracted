use utf8;
package Biblio::Zotero::DB::Schema::Result::Setting;
$Biblio::Zotero::DB::Schema::Result::Setting::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("settings");


__PACKAGE__->add_columns(
  "setting",
  { data_type => "text", is_nullable => 0 },
  "key",
  { data_type => "text", is_nullable => 0 },
  "value",
  { data_type => "", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("setting", "key");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hsuq2LLRARexXF0ZHybsGA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Setting

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::Setting

=head1 TABLE: C<settings>

=head1 ACCESSORS

=head2 setting

  data_type: 'text'
  is_nullable: 0

=head2 key

  data_type: 'text'
  is_nullable: 0

=head2 value

  data_type: (empty string)
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</setting>

=item * L</key>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
