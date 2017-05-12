use utf8;

package Data::OFAC::SDN::Schema::Result::SdnComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Data::OFAC::SDN::Schema::Result::SdnComment

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

=head1 TABLE: C<SDN_COMMENTS>

=cut

__PACKAGE__->table("SDN_COMMENTS");

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

__PACKAGE__->resultset_class('DBIx::Class::ResultSet::PhoneticSearch');

=head1 PRIMARY KEY

=over 4

=item * L</ent_num>

=back

=cut

#__PACKAGE__->set_primary_key("ent_num");

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 16:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Aqmj7o4OjqAK553p84L3Bw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
