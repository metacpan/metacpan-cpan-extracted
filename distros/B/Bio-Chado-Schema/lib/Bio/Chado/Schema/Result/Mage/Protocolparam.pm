package Bio::Chado::Schema::Result::Mage::Protocolparam;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Protocolparam::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Protocolparam::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Protocolparam

=head1 DESCRIPTION

Parameters related to a
protocol. For example, if the protocol is a soak, this might include attributes of bath temperature and duration.

=cut

__PACKAGE__->table("protocolparam");

=head1 ACCESSORS

=head2 protocolparam_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'protocolparam_protocolparam_id_seq'

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 datatype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 unittype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "protocolparam_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "protocolparam_protocolparam_id_seq",
  },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "datatype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "unittype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("protocolparam_id");

=head1 RELATIONS

=head2 unittype

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "unittype",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "unittype_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 protocol

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Bio::Chado::Schema::Result::Mage::Protocol",
  { protocol_id => "protocol_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 datatype

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "datatype",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "datatype_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XUN/C0TOU8idi8i3hGBeMg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
