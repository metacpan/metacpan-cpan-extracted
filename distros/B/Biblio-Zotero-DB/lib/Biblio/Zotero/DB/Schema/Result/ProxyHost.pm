use utf8;
package Biblio::Zotero::DB::Schema::Result::ProxyHost;
$Biblio::Zotero::DB::Schema::Result::ProxyHost::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("proxyHosts");


__PACKAGE__->add_columns(
  "hostid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "proxyid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "hostname",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("hostid");


__PACKAGE__->belongs_to(
  "proxyid",
  "Biblio::Zotero::DB::Schema::Result::Proxy",
  { proxyid => "proxyid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xIAGHXJ3cdldqMPb8gE8YQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ProxyHost

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ProxyHost

=head1 TABLE: C<proxyHosts>

=head1 ACCESSORS

=head2 hostid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 proxyid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 hostname

  data_type: 'text'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</hostid>

=back

=head1 RELATIONS

=head2 proxyid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Proxy>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
