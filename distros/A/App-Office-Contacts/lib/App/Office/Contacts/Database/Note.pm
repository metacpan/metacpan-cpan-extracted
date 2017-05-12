package App::Office::Contacts::Database::Note;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For decode().

use Moo;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub add
{
	my($self, $note) = @_;

	$self -> db -> logger -> log(debug => 'Database::Note.add(...)');
	$self -> save_note_record('add', $note);

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $note_id) = @_;

	$self -> db -> logger -> log(debug => "Database::Note.delete($note_id)");

	$self -> db -> simple -> delete('notes', {id => $note_id})
		|| die $self -> db -> simple -> error;

} # End of delete.

# -----------------------------------------------

sub get_notes
{
	my($self, $entity_type, $entity_id) = @_;

	$self -> db -> logger -> log(debug => "Database::Note.get_notes($entity_type, $entity_id)");

	my($result) = $self -> db -> simple -> query('select * from notes where entity_type = ? and entity_id = ? order by timestamp desc', $entity_type, $entity_id)
		|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_notes.

# --------------------------------------------------

sub save_note_record
{
	my($self, $context, $note) = @_;

	$self -> db -> logger -> log(debug => "Database::Note.save_note_record($context, ...)");

	my($table_name) = 'notes';

	if ($context eq 'add')
	{
		$$note{id} = $self -> db -> library -> insert_hashref_get_id($table_name, $note);
	}
	else
	{
	 	$self -> db -> simple -> update($table_name, $note, {id => $$note{id} })
			|| die $self -> db -> simple -> error;
	}

} # End of save_note_record.

# -----------------------------------------------

sub update
{
	my($self, $note) = @_;

	$self -> db -> logger -> log(debug => "Database::Note.update($$note{id})");
	$self -> db -> simple -> update('notes', $note, {id => $$note{id} })
		|| die $self -> db -> simple -> error;

	return 'Updated note';

} # End of update.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Note - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

This module extends L<App::Office::Contacts::Database::Base>, with these attributes:

=head1 Object attributes

=over 4

=item o (None)

=back

=head1 Methods

=head2 add($note)

Adds the given $note to the 'notes' table.

=head2 delete($note_id)

Deletes the note with the given $note_id from the 'notes' table.

=head2 get_notes($entity_type, $entity_id)

Returns a list of note with the given $entity_type ('organization' or 'person'), for the entity
with the given $entity_id.

=head2 save_note_record($context, $note)

Saves the given $note to the 'notes' table. $context is 'add'.

=head2 update($note)

Updates the given $note in the 'notes' table.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
