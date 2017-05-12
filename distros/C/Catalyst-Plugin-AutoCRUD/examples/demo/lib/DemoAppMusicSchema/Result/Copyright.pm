package DemoAppMusicSchema::Result::Copyright;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::Copyright

=cut

__PACKAGE__->table("copyright");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 rights_owner

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 copyright_year

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "rights_owner",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "copyright_year",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 tracks

Type: has_many

Related object: L<DemoAppMusicSchema::Result::Track>

=cut

__PACKAGE__->has_many(
  "tracks",
  "DemoAppMusicSchema::Result::Track",
  { "foreign.copyright_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 18:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XrtTaWWL6OkKBm+Aa7mqcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
