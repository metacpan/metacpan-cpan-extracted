package DemoAppMusicSchema::Result::Track;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppMusicSchema::Result::Track

=cut

__PACKAGE__->table("track");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 length

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 album_id

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 0

=head2 copyright_id

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 1

=head2 sales

  data_type: 'int'
  is_nullable: 1

=head2 releasedate

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "length",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "album_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
  "copyright_id",
  { data_type => "int", is_foreign_key => 1, is_nullable => 1 },
  "sales",
  { data_type => "int", is_nullable => 1 },
  "releasedate",
  { data_type => "date", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 copyright

Type: belongs_to

Related object: L<DemoAppMusicSchema::Result::Copyright>

=cut

__PACKAGE__->belongs_to(
  "copyright",
  "DemoAppMusicSchema::Result::Copyright",
  { id => "copyright_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oLD7EdgKsW7g36BadJymew


sub display_name {
    my $row = shift;
    return $row->title;
}

1;
