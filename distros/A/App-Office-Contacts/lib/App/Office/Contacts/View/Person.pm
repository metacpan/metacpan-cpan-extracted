package App::Office::Contacts::View::Person;

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

	$self -> db -> logger -> log(debug => "View::Person.add($user_id, ...)");

	# Force the user_id into the person's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($person)          = {};
	$$person{creator_id} = $user_id;

	for my $field_name ($result -> valids)
	{
		$$person{$field_name} = $result -> get_value($field_name) || '';
	}

	# Force an empty preferred name to match the given name(s).
	# In App::Office::Contacts::Util::Validator,
	# given_names is mandatory but preferred_name is not.

	if (! $$person{preferred_name})
	{
		$$person{preferred_name} = $$person{given_names};
	}

	# Force the name to match "preferred name<1 space>surname".
	# There is no 'if' because there is no input field for 'name'.

	$$person{name} = "$$person{preferred_name} $$person{surname}";

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => "Adding person $$person{name}...");
	$self -> db -> logger -> log(debug => "$_ => $$person{$_}") for sort keys %$person;
	$self -> db -> logger -> log(debug => '-' x 50);

	return $self -> db -> person -> add($person);

} # End of add.

# -----------------------------------------------

sub build_add_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'View::Person.build_add_html()');

	my($html) = $self -> db -> templater -> render
	(
		'person.tx',
		{
			communication_type_id => mark_raw($self -> build_simple_menu('add_person', 'communication_type', 1) ),
			context               => 'add',
			email_field           => mark_raw($self -> build_email_menus('add_person', []) ),
			facebook_tag          => '',
			gender_id             => mark_raw($self -> build_simple_menu('add_person', 'gender', 1) ),
			given_names           => '',
			homepage              => '',
			organization_id       => 0,
			person_id             => 0,
			person_name           => '',
			phone_field           => mark_raw($self -> build_phone_menus('add_person', []) ),
			preferred_name        => '',
			role_id               => mark_raw($self -> build_simple_menu('add_person', 'role', 1) ),
			sid                   => $self -> db -> session -> id,
			surname               => '',
			title_id              => mark_raw($self -> build_simple_menu('add_person', 'title', 1) ),
			twitter_tag           => '',
			ucfirst_context       => 'Add',
			visibility_id         => mark_raw($self -> build_simple_menu('add_person', 'visibility', 1) ),
		}
	);

	# Make browser happy by turning the HTML into 1 long line.

	$html =~ s/\n//g;

	return $html;

} # End of build_add_html.

# -----------------------------------------------

sub build_tab_html
{
	my($self, $person, $occupations, $notes) = @_;

	$self -> db -> logger -> log(debug => "View::Person.build_tab_html($$person{name}, ...)");

	my(@tab) =
	(
		{
			body   => mark_raw($self -> build_update_html($person) ),
			header => 'Update person',
			name   => 'person_detail_tab',
		},
		{
			body   => mark_raw($self -> view -> occupation -> build_occupation_html($person, $occupations) ),
			header => 'Occupations',
			name   => 'person_occupation_tab',
		},
		{
			body   => mark_raw($self -> view -> note -> build_person_html($person, $notes) ),
			header => 'Notes',
			name   => 'person_note_tab',
		},
	);

	return $self -> db -> templater -> render
	(
		'tab.tx',
		{
			list => [@tab],
			div  => 'update_person_div',
		}
	);

} # End of build_tab_html.

# -----------------------------------------------

sub build_update_html
{
	my($self, $person) = @_;

	$self -> db -> logger -> log(debug => "View::Person.build_update_html($$person{name})");

	for my $key (sort keys %$person)
	{
		$self -> db -> logger -> log(debug => "$key => $$person{$key}.");
	}

	my($param) =
	{
		communication_type_id => mark_raw($self -> build_simple_menu('update_person', 'communication_type', $$person{communication_type_id}) ),
		context               => 'update',
		email_field           => mark_raw($self -> build_email_menus('update_person', $$person{email_phone}) ),
		facebook_tag          => mark_raw($$person{facebook_tag}),
		gender_id             => mark_raw($self -> build_simple_menu('update_person', 'gender', $$person{gender_id}) ),
		given_names           => mark_raw($$person{given_names}),
		homepage              => mark_raw($$person{homepage}),
		person_id             => $$person{id},
		person_name           => $$person{name},
		phone_field           => mark_raw($self -> build_phone_menus('update_person', $$person{email_phone}) ),
		preferred_name        => mark_raw($$person{preferred_name}),
		role_id               => mark_raw($self -> build_simple_menu('update_person', 'role', $$person{role_id}) ),
		sid                   => $self -> db -> session -> id,
		surname               => mark_raw($$person{surname}),
		title_id              => mark_raw($self -> build_simple_menu('update_person', 'title', $$person{title_id}) ),
		twitter_tag           => mark_raw($$person{twitter_tag}),
		ucfirst_context       => 'Update',
		visibility_id         => mark_raw($self -> build_simple_menu('update_person', 'visibility', $$person{visibility_id}) ),
	};

	# Make browser happy by turning the HTML into 1 long line.

	my($template) = $self -> db -> templater -> render
	(
		'person.tx',
		$param
	);
	$template =~ s/\n//g;

	return $template;

} # End of build_update_html.

# -----------------------------------------------

sub format_search_result
{
	my($self, $name, $people) = @_;

	$self -> db -> logger -> log(debug => "View::Person.format_search_result($name, @{[scalar @$people]})");

	my(@row);

	if ($name && ($#$people >= 0) )
	{
		my($previous_surname) = '';
		my($sid)              = $self -> db -> session -> id;

		my($email, $email_address);
		my($i);
		my($person, $phone);

		for $person (@$people)
		{
			$name = $$person{name};

			for $i (0 .. $#{$$person{email_phone} })
			{
				$email         = $$person{email_phone}[$i]{email};
				$email_address = $$email{address} ? qq|<a href="mailto:$$email{address}">$$email{address}</a>| : '';
				$phone         = $$person{email_phone}[$i]{phone};

				push @row,
				{
					email       => $email_address,
					email_type  => $$email{type_name},
					given_names => $$person{given_names},
					id          => $$person{id},
					name        => $name ? qq|<a href="#" onClick="display_person($$person{id}, '$sid')">$name</a>| : '-',
					phone       => $$phone{number},
					phone_type  => $$phone{type_name},
					role        => $name ? $self -> db -> library -> get_role_via_id($$person{role_id}) : '-',
					surname     => $previous_surname eq $$person{surname} ? '' : $$person{surname},
					type        => 'Person', # Not $i == 0 ? 'Person' : '-', which sorts '-' first :-(.
				};

				# Blanking out the names means they are not repeated in the output (HTML) table.

				$name             = '';
				$previous_surname = $$person{surname};
			}
		}
	}

	return [@row];

} # End of format_search_result.

# -----------------------------------------------

sub update
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Person.update($user_id, ...)");

	# Force the user_id into the person's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($person)          = {};
	$$person{creator_id} = $user_id;
	$$person{id}         = $result -> get_value('person_id');

	for my $field_name ($result -> valids)
	{
		$$person{$field_name} = $result -> get_value($field_name) || '';
	}

	# Force the Name to match "Given name(s)<1 space>Surname".
	# There is no 'if' because there is no input field for 'name'.

	$$person{name} = "$$person{given_names} $$person{surname}";

	# Force an empty Preferred name to match the Given name(s).

	if (! $$person{preferred_name})
	{
		$$person{preferred_name} = $$person{given_names};
	}

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => "Updating person $$person{name}...");
	$self -> db -> logger -> log(debug => "$_ => $$person{$_}") for sort keys %$person;
	$self -> db -> logger -> log(debug => '-' x 50);

	$self -> db -> person -> update($person);

} # End of update.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Person - A web-based contacts manager

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

=head2 add($user_id, $result)

Adds a person.

=head2 build_add_html()

Returns the HTML for the 'Add Person' tab.

=head2 build_tab_html($person, $occupations, $notes)

Returns the HTML for the 3 tabs: 'Update Person', 'Add Occupation' and 'Add Notes'.

=head2 build_update_html($person)

Returns the HTML for the 'Update Person' tab.

=head2 format_search_result($name, $people)

Returns the HTML for the result of searching for people.

=head2 update($user_id, $result)

Updates a person.

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
