package App::Office::Contacts::View::Occupation;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Text::Xslate 'mark_raw';

extends 'App::Office::Contacts::View::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub add
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Occupation.add($user_id, ...)");

	# Force the user_id into the occupation's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($occupation)          = {};
	$$occupation{creator_id} = $user_id;

	my($occupation_title);
	my($value);

	# When adding an occupation, the person_name field is not set, so person_id is used.
	# When adding a staff member, the organization_name is not set, so organization_id is used.

	for my $field_name ($result -> valids)
	{
		$value = $result -> get_value($field_name);

		if ($field_name eq 'occupation_title')
		{
			# Convert the occupation's title into an id.

			$occupation_title        = $value; # For the log.
			my($occupation_title_id) = $self -> db -> library -> validate_name('occupation_titles', $value);

			if ($occupation_title_id == 0)
			{
				$self -> db -> occupation -> save_occupation_title($value);

				$occupation_title_id = $self -> db -> library -> validate_name('occupation_titles', $value);
			}

			$$occupation{occupation_title_id} = $occupation_title_id;
		}
		elsif ($field_name eq 'organization_id')
		{
			$$occupation{organization_id} = $value;
		}
		elsif ($field_name eq 'organization_name')
		{
			# Convert the organization's name into an id.

			$$occupation{organization_id} = $self -> db -> library -> validate_name('organizations', $value);
		}
		elsif ($field_name eq 'person_id')
		{
			$$occupation{person_id} = $value;
		}
		elsif ($field_name eq 'person_name')
		{
			# Convert the persons's name into an id.

			$$occupation{person_id} = $self -> db -> library -> validate_name('people', $value);
		}
		else # sid.
		{
			$$occupation{$field_name} = $value;
		}
	}

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => "Adding occupation '$occupation_title' ...");
	$self -> db -> logger -> log(debug => "$_ => $$occupation{$_}") for sort keys %$occupation;
	$self -> db -> logger -> log(debug => '-' x 50);

	$self -> db -> occupation -> add($occupation);

	# Save the organization id and person id for use in constructing the response.

	$self -> db -> session -> param(staff_organization_id => $$occupation{organization_id});
	$self -> db -> session -> param(occupation_person_id  => $$occupation{person_id});

} # End of add.

# -----------------------------------------------

sub build_occupation_html
{
	my($self, $person, $occupations) = @_;

	$self -> db -> logger -> log(debug => 'Entered View::Occupation.build_occupation_html');

	my($count) = scalar @$occupations;

	return $self -> db -> templater -> render
	(
		'occupation.tx',
		{
			name            => mark_raw($$person{name}),
			occupation_list => $count ? mark_raw($self -> format_occupations($$person{id}, $occupations) ) : '',
			sid             => $self -> db -> session -> id,
		}
	);

} # End of build_occupation_html.

# -----------------------------------------------

sub build_staff_html
{
	my($self, $organization, $staff) = @_;

	$self -> db -> logger -> log(debug => 'Entered View::Occupation.build_staff_html');

	my($count) = scalar @$staff;

	return $self -> db -> templater -> render
	(
		'staff.tx',
		{
			name       => mark_raw($$organization{name}),
			sid        => $self -> db -> session -> id,
			staff_list => $count ? mark_raw($self -> format_staff($$organization{id}, $staff) ) : '',
		}
	);

} # End of build_staff_html.

# -----------------------------------------------

sub format_occupations
{
	my($self, $person_id, $list) = @_;

	$self -> db -> logger -> log(debug => "View::Occupation.format_occupations($person_id, ...)");

	my($sid)  = $self -> db -> session -> id;
	my($html) = <<EOS;
<table class="display" id="occ_table_div" cellpadding="0" cellspacing="0" border="0">
<thead>
<tr>
	<th align="left">Organization</th>
	<th align="left">Occupation</th>
	<th align="left">Action</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);
	my($delete);
	my($organization);

	for my $row (@$list)
	{
		$class        = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$organization = qq|<a href="#" onClick="display_organization($$row{organization_id}, '$sid')">$$row{organization_name}</a>|;
		$delete       = qq|<a href="#" onClick="delete_occupation('$$row{person_name}', $person_id, $$row{organization_id}, $$row{occupation_id})">Delete</a>|;
		$html         .= <<EOS;
<tr class="$class">
	<td>$organization</td>
	<td>$$row{occupation_title}</td>
	<td>$delete</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
</table>
EOS

	return $html;

} # End of format_occupations.

# -----------------------------------------------

sub format_staff
{
	my($self, $organization_id, $list) = @_;

	$self -> db -> logger -> log(debug => "View::Occupation.format_staff($organization_id, ...)");

	my($sid)  = $self -> db -> session -> id;
	my($html) = <<EOS;
<table class="display" id="staff_table_div" cellpadding="0" cellspacing="0" border="0">
<thead>
<tr>
	<th align="left">Person</th>
	<th align="left">Occupation</th>
	<th align="left">Action</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);
	my($delete);
	my($person);

	for my $row (@$list)
	{
		$class   = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$person  = qq|<a href="#" onClick="display_person($$row{person_id}, '$sid')">$$row{person_name}</a>|;
		$delete  = qq|<a href="#" onClick="delete_staff('$$row{person_name}', $$row{person_id}, $organization_id, $$row{occupation_id})">Delete</a>|;
		$html    .= <<EOS;
<tr class="$class">
	<td>$person</td>
	<td>$$row{occupation_title}</td>
	<td>$delete</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
</table>
EOS

	return $html;

} # End of format_staff.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Occupation - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class extends L<App::Office::Contacts::View::Base>, with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 report_add($user_id, $result)

Adds an occupation for a person or a staff member for an organization.

=head2 build_occupation_html($person, $occupations)

Returns the HTML for the given list of $occupations for the given $person.

=head2 build_staff_html($organization, $staff)

Returns the HTML for the given list of $staff for the given $organization.

=head2 format_occupations($person_id, $list)

Formats the HTML for the given list of $occupations for the given $person.

=head2 format_staff($organization_id, $list)

Formats the HTML for the given list of $staff for the given $organization.

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
