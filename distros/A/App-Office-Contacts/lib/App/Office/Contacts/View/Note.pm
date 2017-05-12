package App::Office::Contacts::View::Note;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Text::Xslate 'mark_raw';

extends 'App::Office::Contacts::View::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub build_organization_html
{
	my($self, $organization, $notes) = @_;

	$self -> db -> logger -> log(debug => "View::Note.build_organization_html($$organization{id}, ...)");

	return $self -> db -> templater -> render
	(
		'note.tx',
		{
			context   => 'org',
			name      => mark_raw($$organization{name}),
			note_list => $#$notes >= 0 ? mark_raw($self -> format_organization_notes($$organization{id}, $notes) ) : '',
		}
	);

} # End of build_organization_html.

# -----------------------------------------------

sub build_person_html
{
	my($self, $person, $notes) = @_;

	$self -> db -> logger -> log(debug => "View::Note.build_person_html($$person{id}, ...)");

	return $self -> db -> templater -> render
	(
		'note.tx',
		{
			context   => 'person',
			name      => mark_raw($$person{name}),
			note_list => $#$notes >= 0 ? mark_raw($self -> format_person_notes($$person{id}, $notes) ) : '',
		}
	);

} # End of build_person_html.

# -----------------------------------------------

sub format_organization_notes
{
	my($self, $organization_id, $list) = @_;

	$self -> db -> logger -> log(debug => "View::Note.format_organization_notes($organization_id, ...)");

	my($html) = <<EOS;
<table  align="center" id="org_note_table_div" cellpadding="0" cellspacing="0" border="0">
<thead>
<tr>
	<th align="left">Timestamp and note</th>
	<th align="left">Action</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);
	my($delete);
	my($timestamp, $text);
	my($update);

	for my $row (@$list)
	{
		$class     = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$delete    = qq|<a href="#org" onClick="delete_org_note($$row{id})">Delete</a>|;
		$timestamp = $self -> format_timestamp($$row{timestamp});
		$update    = qq|<a href="#org" onClick="update_org_note($count, $$row{id})">Update</a>|;
		$text      = qq|<textarea id="org_note_$count" cols="100" rows="2">$$row{body}</textarea>|;
		$html      .= <<EOS;
<tr class="$class">
	<td>$count: $timestamp</td>
	<td>$delete</td>
</tr>
<tr class="$class">
	<td>$text</td>
	<td>$update</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
</table>
EOS

	return $html;

} # End of format_organization_notes.

# -----------------------------------------------

sub format_person_notes
{
	my($self, $person_id, $list) = @_;

	$self -> db -> logger -> log(debug => "View::Note.format_person_notes($person_id, ...)");

	my($html) = <<EOS;
<table  align="center" id="person_note_table_div" cellpadding="0" cellspacing="0" border="0">
<thead>
<tr>
	<th align="left">Timestamp and note</th>
	<th align="left">Action</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);
	my($delete);
	my($timestamp, $text);
	my($update);

	for my $row (@$list)
	{
		$class     = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$delete    = qq|<a href="#person" onClick="delete_person_note($$row{id})">Delete</a>|;
		$timestamp = $self -> format_timestamp($$row{timestamp});
		$update    = qq|<a href="#person" onClick="update_person_note($count, $$row{id})">Update</a>|;
		$text      = qq|<textarea id="person_note_$count" cols="100" rows="2">$$row{body}</textarea>|;
		$html      .= <<EOS;
<tr class="$class">
	<td>$count: $timestamp</td>
	<td>$delete</td>
</tr>
<tr class="$class">
	<td>$text</td>
	<td>$update</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
</table>
EOS

	return $html;

} # End of format_person_notes.

# -----------------------------------------------

sub add
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Note.add($user_id, ...)");

	# Force the user_id into the person's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($note)           = {};
	$$note{creator_id}  = $user_id;
	$$note{entity_id}   = $result -> get_value('entity_id');
	$$note{entity_type} = $result -> get_value('entity_type');
	$$note{body}        = $result -> get_value('body');

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => 'Adding note ...'); # Skip note because of potential length.
	$self -> db -> logger -> log(debug => "$_ => $$note{$_}") for sort grep{! /^body$/} keys %$note;

	my($text) = $$note{body};
	$text     = length($text) > 20 ? (substr($text, 0, 20) . '...') : $text;

	$self -> db -> logger -> log(debug => "note => $text");
	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> note -> add($note);

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Note.delete($user_id, ...)");
	$self -> db -> note -> delete($result -> get_value('note_id') );

} # End of delete.

# -----------------------------------------------

sub update
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Note.update($user_id, ...)");

	# Force the user_id into the person's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($note)           = {};
	$$note{creator_id}  = $user_id;
	$$note{entity_id}   = $result -> get_value('entity_id');
	$$note{entity_type} = $result -> get_value('entity_type');
	$$note{body}        = $result -> get_value('body') || ''; # Content may have been deleted.
	$$note{id}          = $result -> get_value('note_id');

	$self -> db -> note -> update($note);

} # End of update.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Note - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

Each instance of this class is a L<Moo>-based object with these attributes:

=head1 Object attributes

Each instance of this class extends L<App::Office::Contacts::View::Base>, with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 add($user_id, $result)

Adds a Note.

=head2 build_organization_html($organization, $notes)

Returns the HTML for the given list of $notes for the given $organization.

=head2 build_person_html($person, $notes)

Returns the HTML for the given list of $notes for the given $person.

=head2 delete($user_id, $result)

Deletes a Note.

=head2 format_organization_notes($organization_id, $list)

Formats the HTML for the given list of $notes for the given $organization.

=head2 format_person_notes($person_id, $list)

Formats the HTML for the given list of $notes for the given $person.

=head2 update($user_id, $result)

Updates a Note.

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
