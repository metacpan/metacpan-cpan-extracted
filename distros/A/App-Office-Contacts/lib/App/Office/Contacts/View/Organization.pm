package App::Office::Contacts::View::Organization;

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

	$self -> db -> logger -> log(debug => "View::Organization.add($user_id, ...)");

	# Force the user_id into the organizations's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($organization)          = {};
	$$organization{creator_id} = $user_id;

	for my $field_name ($result -> valids)
	{
		$$organization{$field_name} = $result -> get_value($field_name) || '';
	}

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => "Adding organization $$organization{name}...");
	$self -> db -> logger -> log(debug => "$_ => $$organization{$_}") for sort keys %$organization;
	$self -> db -> logger -> log(debug => '-' x 50);

	return $self -> db -> organization -> add($organization);

} # End of add.

# -----------------------------------------------

sub build_add_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'View::Org.build_add_html()');

	my($html) = $self -> db -> templater -> render
	(
		'organization.tx',
		{
			communication_type_id => mark_raw($self -> build_simple_menu('add_org', 'communication_type', 1) ),
			context               => 'add',
			email_field           => mark_raw($self -> build_email_menus('add_org', []) ),
			facebook_tag          => '',
			homepage              => '',
			name                  => '',
			organization_id       => 0,
			phone_field           => mark_raw($self -> build_phone_menus('add_org', []) ),
			roles                 => mark_raw($self -> build_simple_menu('add_org', 'role', 1) ),
			sid                   => $self -> db -> session -> id,
			twitter_tag           => '',
			ucfirst_context       => 'Add',
			visibility_id         => mark_raw($self -> build_simple_menu('add_org', 'visibility', 1) ),
		}
	);

	# Make browser happy by turning the HTML into 1 long line.

	$html =~ s/\n//g;

	return $html;

} # End of build_add_html.

# -----------------------------------------------

sub build_tab_html
{
	my($self, $organization, $occupations, $notes) = @_;

	$self -> db -> logger -> log(debug => "View::Org.build_tab_html($$organization{name}, ...)");

	my(@tab) =
	(
		{
			body   => mark_raw($self -> build_update_html($organization) ),
			header => 'Update organization',
			name   => 'org_detail_tab',
		},
		{
			body   => mark_raw($self -> view -> occupation -> build_staff_html($organization, $occupations) ),
			header => 'Staff',
			name   => 'org_staff_tab',
		},
		{
			body   => mark_raw($self -> view -> note -> build_organization_html($organization, $notes) ),
			header => 'Notes',
			name   => 'person_note_tab',
		},
	);

	my($template) = $self -> db -> templater -> render
	(
		'tab.tx',
		{
			list => [@tab],
			div  => 'update_org_div',
		}
	);

	return $template;

} # End of build_tab_html.

# -----------------------------------------------

sub build_update_html
{
	my($self, $organization) = @_;

	$self -> db -> logger -> log(debug => "View::Org.build_update_html(...)");

	my($param) =
	{
		communication_type_id => mark_raw($self -> build_simple_menu('update_org', 'communication_type', $$organization{communication_type_id}) ),
		context               => 'update',
		email_field           => mark_raw($self -> build_email_menus('update_org', $$organization{email_phone}) ),
		facebook_tag          => mark_raw($$organization{facebook_tag}),
		homepage              => mark_raw($$organization{homepage}),
		id                    => $$organization{id},
		name                  => mark_raw($$organization{name}),
		org_id                => $$organization{id},
		phone_field           => mark_raw($self -> build_phone_menus('update_org', $$organization{email_phone}) ),
		roles                 => mark_raw($self -> build_simple_menu('update_org', 'role', $$organization{role_id}) ),
		sid                   => $self -> db -> session -> id,
		twitter_tag           => mark_raw($$organization{twitter_tag}),
		ucfirst_context       => 'Update',
		visibility_id         => mark_raw($self -> build_simple_menu('update_org', 'visibility', $$organization{visibility_id}) ),
	};

	my($template) = $self -> db -> templater -> render
	(
		'organization.tx',
		$param
	);

	# Make browser happy by turning the HTML into 1 long line.

	$template =~ s/\n//g;

	return $template;

} # End of build_update_html.

# -----------------------------------------------

sub format_search_result
{
	my($self, $name, $organizations) = @_;

	$self -> db -> logger -> log(debug => "View::Org.format_search_result($name, @{[scalar @$organizations]})");

	my(@row);

	if ($name && ($#$organizations >= 0) )
	{
		my($sid) = $self -> db -> session -> id;

		my($email, $email_address);
		my($i);
		my($organization);
		my($phone);

		for $organization (@$organizations)
		{
			$name = $$organization{name};

			for $i (0 .. $#{$$organization{email_phone} })
			{
				$email         = $$organization{email_phone}[$i]{email};
				$email_address = $$email{address} ? mark_raw(qq|<a href="mailto:$$email{address}">$$email{address}</a>|) : '';
				$phone         = $$organization{email_phone}[$i]{phone};

				push @row,
				{
					email      => $email_address,
					email_type => $$email{type_name},
					id         => $$organization{id},
					name       => $name ? mark_raw(qq|<a href="#" onClick="display_organization($$organization{id}, '$sid')">$name</a>|) : '-',
					phone      => $$phone{number},
					phone_type => $$phone{type_name},
					role       => $name ? mark_raw($self -> db -> library -> get_role_via_id($$organization{role_id}) ) : '-',
					type       => 'Organization',
				};

				# Blanking out the name means it is not repeated in the output (HTML) table.

				$name = '';
			}
		}
	}

	return [@row];

} # End of format_search_result.

# -----------------------------------------------

sub update
{
	my($self, $user_id, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Organization.update($user_id, ...)");

	# Force the user_id into the person's record, so it is available elsewhere.
	# Note: This is the user_id of the person logged on.

	my($organization)          = {};
	$$organization{creator_id} = $user_id;
	$$organization{id}         = $result -> get_value('organization_id');

	for my $field_name ($result -> valids)
	{
		$$organization{$field_name} = $result -> get_value($field_name) || '';
	}

	$self -> db -> logger -> log(debug => '-' x 50);
	$self -> db -> logger -> log(debug => "Updating organization $$organization{name}...");
	$self -> db -> logger -> log(debug => "$_ => $$organization{$_}") for sort keys %$organization;
	$self -> db -> logger -> log(debug => '-' x 50);

	return $self -> db -> organization -> update($organization);

} # End of update.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Organization - A web-based contacts manager

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

Adds an organization.

=head2 build_add_html()

Returns the HTML for the 'Add Organization' tab.

=head2 build_tab_html($organization, $occupations, $notes)

Returns the HTML for the 3 tabs: 'Update Organization', 'Add Staff' and 'Add Notes'.

=head2 build_update_html($organization)

Returns the HTML for the 'Update Organization' tab.

=head2 format_search_result($name, $organizations)

Returns the HTML for the result of searching for organizations.

=head2 update($user_id, $result)

Updates an organization.

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
