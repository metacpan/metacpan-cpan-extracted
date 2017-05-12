use utf8;
package t::lib::Schema2::Result::Myrole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

t::lib::Schema2::Result::Myrole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<myroles>

=cut

__PACKAGE__->table("myroles");

=head1 ACCESSORS

=head2 mylogin_name

  data_type: 'text'
  is_nullable: 1

=head2 myrole

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mylogin_name",
  { data_type => "text", is_nullable => 1 },
  "myrole",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-04-01 11:38:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:amsDMXsdTCNa2yZOvOLYbw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
