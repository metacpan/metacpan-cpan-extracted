use utf8;

package Data::OFAC::SDN::Schema::Result::Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Data::OFAC::SDN::Schema::Result::Address

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

=head1 TABLE: C<ADDRESS>

=cut

__PACKAGE__->table("ADDRESS");

=head1 ACCESSORS

=head2 ent_num

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0

=head2 add_num

  data_type: 'numeric'
  is_nullable: 0

=head2 citystateprovincepostalcode

  data_type: 'text'
  is_nullable: 1

=head2 country

  data_type: 'text'
  is_nullable: 1

=head2 add_remarks

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "ent_num",
    { data_type => "numeric", is_foreign_key => 1, is_nullable => 0 },
    "add_num",
    { data_type => "numeric", is_nullable => 0 },
    "citystateprovincepostalcode",
    { data_type => "text", is_nullable => 1, phonetic_search => 1 },
    "country",
    { data_type => "text", is_nullable => 1, phonetic_search => 1 },
    "add_remarks",
    { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->resultset_class('DBIx::Class::ResultSet::PhoneticSearch');

=head1 RELATIONS

=head2 ent_num

Type: belongs_to

Related object: L<Data::OFAC::SDN::Schema::Result::Sdn>

=cut

__PACKAGE__->belongs_to(
    "ent_num",
    "Data::OFAC::SDN::Schema::Result::Sdn",
    { ent_num => "ent_num" },
    {   is_deferrable => 0,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 16:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rUOg96DZnP9u/LChYJLnnQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
