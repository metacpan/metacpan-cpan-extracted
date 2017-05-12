package DemoAppMusicSchema::Result::SleeveNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::SleeveNote

=cut

__PACKAGE__->table("sleeve_notes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 text

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 album_id

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "text",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("album_id_unique", ["album_id"]);

=head1 RELATIONS

=head2 album

Type: belongs_to

Related object: L<DemoAppMusicSchema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "album",
  "DemoAppMusicSchema::Result::Album",
  { id => "album_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 18:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ijZYnervlxCo3N/1mtZMow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
