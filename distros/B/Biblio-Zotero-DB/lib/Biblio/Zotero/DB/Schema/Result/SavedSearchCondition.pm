use utf8;
package Biblio::Zotero::DB::Schema::Result::SavedSearchCondition;
$Biblio::Zotero::DB::Schema::Result::SavedSearchCondition::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("savedSearchConditions");


__PACKAGE__->add_columns(
  "savedsearchid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "searchconditionid",
  { data_type => "int", is_nullable => 0 },
  "condition",
  { data_type => "text", is_nullable => 1 },
  "operator",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "required",
  { data_type => "none", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("savedsearchid", "searchconditionid");


__PACKAGE__->belongs_to(
  "savedsearchid",
  "Biblio::Zotero::DB::Schema::Result::SavedSearch",
  { savedsearchid => "savedsearchid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JqpiVvq1q0JP97aVmLuMhQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SavedSearchCondition

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::SavedSearchCondition

=head1 TABLE: C<savedSearchConditions>

=head1 ACCESSORS

=head2 savedsearchid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 searchconditionid

  data_type: 'int'
  is_nullable: 0

=head2 condition

  data_type: 'text'
  is_nullable: 1

=head2 operator

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 required

  data_type: 'none'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</savedsearchid>

=item * L</searchconditionid>

=back

=head1 RELATIONS

=head2 savedsearchid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::SavedSearch>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
