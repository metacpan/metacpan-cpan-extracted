use utf8;

package Data::OFAC::SDN::Schema::Result::Sdn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Data::OFAC::SDN::Schema::Result::Sdn

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

=head1 TABLE: C<SDN>

=cut

__PACKAGE__->table("SDN");

=head1 ACCESSORS

=head2 ent_num

  data_type: 'numeric'
  is_nullable: 0

=head2 sdn_name

  data_type: 'text'
  is_nullable: 1

=head2 sdn_type

  data_type: 'text'
  is_nullable: 0

=head2 program

  data_type: 'text'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 call_sign

  data_type: 'text'
  is_nullable: 1

=head2 vess_type

  data_type: 'text'
  is_nullable: 1

=head2 tonnage

  data_type: 'text'
  is_nullable: 1

=head2 grt

  data_type: 'text'
  is_nullable: 1

=head2 vess_flag

  data_type: 'text'
  is_nullable: 1

=head2 vess_owner

  data_type: 'text'
  is_nullable: 1

=head2 remarks

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "ent_num",
    { data_type => "numeric", is_nullable => 0 },
    "sdn_name",
    { data_type => "text", is_nullable => 1, phonetic_search => 1 },
    "sdn_type",
    { data_type => "text", is_nullable => 0 },
    "program",
    { data_type => "text", is_nullable => 0 },
    "title",
    { data_type => "text", is_nullable => 1, phonetic_search => 1 },
    "call_sign",
    { data_type => "text", is_nullable => 1 },
    "vess_type",
    { data_type => "text", is_nullable => 1 },
    "tonnage",
    { data_type => "text", is_nullable => 1 },
    "grt",
    { data_type => "text", is_nullable => 1 },
    "vess_flag",
    { data_type => "text", is_nullable => 1 },
    "vess_owner",
    { data_type => "text", is_nullable => 1 },
    "remarks",
    { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ent_num>

=back

=cut

#__PACKAGE__->set_primary_key("ent_num");

__PACKAGE__->resultset_class('DBIx::Class::ResultSet::PhoneticSearch');

=head1 RELATIONS

=head2 addresses

Type: has_many

Related object: L<Data::OFAC::SDN::Schema::Result::Address>

=cut

__PACKAGE__->has_many(
    "addresses",
    "Data::OFAC::SDN::Schema::Result::Address",
    { "foreign.ent_num" => "self.ent_num" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 alts

Type: has_many

Related object: L<Data::OFAC::SDN::Schema::Result::Alt>

=cut

__PACKAGE__->has_many(
    "alts",
    "Data::OFAC::SDN::Schema::Result::Alt",
    { "foreign.ent_num" => "self.ent_num" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 16:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xYy/SCgpuUw4u4r/QkpzUw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
