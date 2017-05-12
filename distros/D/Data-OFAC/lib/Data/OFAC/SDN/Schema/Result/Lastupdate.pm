use utf8;

package Data::OFAC::SDN::Schema::Result::Lastupdate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Data::OFAC::SDN::Schema::Result::Lastupdate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::PhoneticSearch>

=item * L<DBIx::Class::Core>

=back

=cut

__PACKAGE__->load_components( "PhoneticSearch", "Core" );

=head1 TABLE: C<LASTUPDATE>

=cut

__PACKAGE__->table("LASTUPDATE");

=head1 ACCESSORS

=head2 lastupdatedatetime

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns( "lastupdatedatetime",
    { data_type => "text", is_nullable => 1 },
);

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 16:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X3/XVEpEJTJfUpEv95/FWg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
