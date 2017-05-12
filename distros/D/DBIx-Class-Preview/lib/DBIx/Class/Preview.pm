package DBIx::Class::Preview;

use warnings;
use strict;
use Storable ();
use base qw/DBIx::Class/;

=head1 VERSION

Version 1.000003

=cut

our $VERSION = '1.000003';

=head1 NAME

DBIx::Class::Preview

=head1 SYNOPSIS

Add component to schema class.

  package MyApp::Schema;

  __PACKAGE__->load_components(qw/Schema::Preview/);

  ...

Add component to each result class required to be previewed.

  package MyApp::Schema::Artist;

  __PACKAGE__->load_components('Preview');

  ...

And then elsewhere..

  # turn on preview mode
  $schema->preview_active(1);

  # update a row of a previewed class
  # writes to the artist_preview table instead of the usual artist table
  my $row = $schema->resultset('Artist')->create({ name => 'luke' });

  # publish changes to live tables
  # writes changes from artist_preview to the main artist table
  $schema->publish();

=head1 DESCRIPTION

When preview mode is active, all reads and writes to the previewed sources are redirected to a preview table. When L</publish> is called, these changes are synced to the live table from the previewed table. You will need to set these additional preview tables up yourself - see L</SETUP>.

For example, a moderator making changes to a website could use a schema with preview mode active while normal users got a schema without preview mode. This would enable the moderator to see the changes he's making as he makes them but normal users would not see his changes until they were published.

=head1 SETUP

For each table to be previewed, a separate table needs to be set up which has the same columns as the original table and also two extra columns - 'dirty' and 'deleted'. These extra tables need to be populated with the rows from the original table before they can be used. For example, to setup a preview table for an 'artist' table in MySQL, you might use the following SQL:

  CREATE TABLE artist_preview LIKE artist;
  ALTER TABLE artist_preview ADD COLUMN dirty TINYINT NOT NULL DEFAULT 0;
  ALTER TABLE artist_preview ADD COLUMN deleted TINYINT NOT NULL DEFAULT 0;
  INSERT INTO artist_preview (SELECT *, 0, 0 FROM artist);

Or in SQLite:

  CREATE TABLE artist_preview (
    artistid INTEGER PRIMARY KEY NOT NULL,
    name varchar(100),
    dirty INTEGER DEFAULT '0',
    deleted INTEGER DEFAULT '0'
  );
  insert into artist_preview select *, 0, 0 from artist;

=head1 SCHEMA METHODS

=head2 preview_active

Accessor to activate or deactivate preview mode. Setting this to 0 will cause reads and writes to go to the
original sources and 1 will cause the previewed sources.

=head2 publish

Copies all 'dirty' changes from the previewed sources to the original sources. Essentially this means finding and
deleting all rows from the original table that are marked as deleted in the previewed table and finding and updating
all rows from the original table with the columns from the rows marked as dirty in the previewed tables.

=head2 ISSUES

- Updating a row in the original source will not cause the change to be made to the previewed source as well. This means for previewed sources, al writes should be done while in preview mode to avoid changes being stomped when published. Patches welcome to better handle this behaviour.

- Using the resultset methods 'update' and 'delete' will go uncaught by this module - what will happen is that the previewed rows will be updated but will not be marked as dirty or deleted. You should use update_all or delete_all instead or alternatively send a patch

- You have to create the previewed tables. Some people might find it preferable for the module to provide a method to do it for you. But it doesn't yet.

=head2 BUGS / CONTRIBUTING

The best way is to email the DBIx::Class mailing list (http://lists.scsys.co.uk/mailman/listinfo/dbix-class/)
with a description and/or patch (against svn trunk - http://dev.catalyst.perl.org/repos/bast/DBIx-Class-Preview/1.000/trunk/).
Alternatively email the author directly or use RT.

=cut

__PACKAGE__->mk_group_accessors( 'simple' => qw/_current_partition/ );

sub table {
    my $class       = shift;

    my $table_class = 'DBIx::Class::ResultSource::Table::Previewed';
    $class->ensure_class_loaded($table_class), $class->table_class($table_class)
      unless $class->table_class->isa($table_class);

    my $ret = $class->next::method(@_);
	return $ret;
}

sub update {
    my $self = shift;

	# mark row as dirty
	if ($self->result_source->schema->preview_active() && $self->result_source->can('is_preview_source')) {
		$_[0] = {} unless ref $_[0];
		$_[0]->{dirty} = 1 unless defined $_[0]->{dirty};
	}

    return $self->next::method(@_);
}

sub insert {
    my $self = shift;

	# mark row as dirty
	if ($self->result_source->schema->preview_active() && $self->result_source->can('is_preview_source')) {
		$self->set_column('dirty', 1);
	}

    return $self->next::method(@_);
}

sub delete {
    my $self = shift;

	# mark row as dirty
	if ($self->result_source->schema->preview_active() && $self->result_source->can('is_preview_source')) {
    return $self->update({ deleted => 1 });
	} else {
    return $self->next::method(@_);
  }
}

# dirty col set here by default value on the table def
sub new {
    my $self = shift;
    return $self->next::method(@_);
}

=head1 AUTHOR

  Luke Saunders <luke.saunders@gmail.com>

  Initial development sponsored by and (c) Takkle, Inc. 2007

=head1 CONTRIBUTORS

  Eden Cardim <eden@shadowcatsystems.co.uk>

=head1 LICENSE

  This library is free software under the same license as perl itself

=cut

1;
