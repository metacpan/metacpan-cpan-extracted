use utf8;
package Biblio::Zotero::DB::Schema::Result::ItemAttachment;
$Biblio::Zotero::DB::Schema::Result::ItemAttachment::VERSION = '0.004';
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use base 'DBIx::Class::Core';


__PACKAGE__->table("itemAttachments");


__PACKAGE__->add_columns(
  "itemid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "sourceitemid",
  { data_type => "int", is_foreign_key => 1, is_nullable => 1 },
  "linkmode",
  { data_type => "int", is_nullable => 1 },
  "mimetype",
  { data_type => "text", is_nullable => 1 },
  "charsetid",
  { data_type => "int", is_nullable => 1 },
  "path",
  { data_type => "text", is_nullable => 1 },
  "originalpath",
  { data_type => "text", is_nullable => 1 },
  "syncstate",
  { data_type => "int", default_value => 0, is_nullable => 1 },
  "storagemodtime",
  { data_type => "int", is_nullable => 1 },
  "storagehash",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("itemid");


__PACKAGE__->has_many(
  "annotations",
  "Biblio::Zotero::DB::Schema::Result::Annotation",
  { "foreign.itemid" => "self.itemid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "highlights",
  "Biblio::Zotero::DB::Schema::Result::Highlight",
  { "foreign.itemid" => "self.itemid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->belongs_to(
  "itemid",
  "Biblio::Zotero::DB::Schema::Result::Item",
  { itemid => "itemid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
  "sourceitemid",
  "Biblio::Zotero::DB::Schema::Result::Item",
  { itemid => "sourceitemid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-02 23:02:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u4JJM71EtePId8XMpq4WOQ

# NOTE: extended DBIC schema below

use URI;
use URI::Escape;
use Path::Class;
use Path::Class::URI;

# TODO: document
sub uri {
	my ($self) = @_;
	# TODO handle case where the item in not an attachment
	if(not defined $self->path) {
		# get URI from ItemDataValue table
		URI->new( $self->itemid->item_datas_rs->find(
			{ 'fieldid.fieldname' => 'url', },
			{ prefetch => [ 'fieldid', 'valueid' ] }
		)->valueid->value );
	}
	elsif($self->path =~ /^storage:/) {
		# link to file in storage
		my $key = $self->itemid->key;
		my $subdir = $self->result_source->schema->zotero_storage_directory()->subdir($key);

		my $subdir_uri = $subdir->uri->as_string;

		URI->new_abs( uri_escape( $self->path =~ s/^storage://r ),
				# escaping URI because it may not be actually escaped properly in the DB
			$subdir_uri
		);
	} else {
		# link to file
		file($self->path)->uri; # NOTE this needs to be check for Zotero on non-Unix systems
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemAttachment

=head1 VERSION

version 0.004

=head1 NAME

Biblio::Zotero::DB::Schema::Result::ItemAttachment

=head1 TABLE: C<itemAttachments>

=head1 ACCESSORS

=head2 itemid

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 sourceitemid

  data_type: 'int'
  is_foreign_key: 1
  is_nullable: 1

=head2 linkmode

  data_type: 'int'
  is_nullable: 1

=head2 mimetype

  data_type: 'text'
  is_nullable: 1

=head2 charsetid

  data_type: 'int'
  is_nullable: 1

=head2 path

  data_type: 'text'
  is_nullable: 1

=head2 originalpath

  data_type: 'text'
  is_nullable: 1

=head2 syncstate

  data_type: 'int'
  default_value: 0
  is_nullable: 1

=head2 storagemodtime

  data_type: 'int'
  is_nullable: 1

=head2 storagehash

  data_type: 'text'
  is_nullable: 1

=head1 PRIMARY KEY

=over 4

=item * L</itemid>

=back

=head1 RELATIONS

=head2 annotations

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::Annotation>

=head2 highlights

Type: has_many

Related object: L<Biblio::Zotero::DB::Schema::Result::Highlight>

=head2 itemid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Item>

=head2 sourceitemid

Type: belongs_to

Related object: L<Biblio::Zotero::DB::Schema::Result::Item>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
