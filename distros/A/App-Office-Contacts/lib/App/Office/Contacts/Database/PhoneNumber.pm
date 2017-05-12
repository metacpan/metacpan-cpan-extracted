package App::Office::Contacts::Database::PhoneNumber;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Encode; # For decode().

use Moo;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub delete_phone_number_organization
{
	my($self, $creator_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.delete_phone_number_organization($creator_id, $id)");

	$self -> db -> simple -> delete('phone_organizations', {id => $id})
		|| die $self -> db -> simple -> error;

} # End of delete_phone_number_organization.

# -----------------------------------------------

sub delete_phone_number_person
{
	my($self, $creator_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.delete_phone_number_people($creator_id, $id)");

	$self -> db -> simple -> delete('phone_people', {id => $id})
		|| die $self -> db -> simple -> error;

} # End of delete_phone_number_people.

# -----------------------------------------------

sub get_organizations_and_people
{
	my($self, $user_id, $uc_key) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_organizations_and_people($user_id, $uc_key)");

	# 1: Get phone #s.

	my($result) = $self -> db -> simple -> query("select * from phone_numbers where upper_number like ?", "%$uc_key%")
					|| die $self -> db -> simple -> error;

	# 2: Get org ids and people ids.

	my(@organization_record);
	my(@person_record);

	for my $record (@{$self -> db -> library -> decode_hashref_list($result -> hashes)})
	{
		$result = $self -> db -> simple -> query("select * from phone_organizations where phone_number_id = ?", $$record{id})
					|| die $self -> db -> simple -> error;

		push @organization_record, @{$self -> db -> library -> decode_hashref_list($result -> hashes)};

		$result = $self -> db -> simple -> query("select * from phone_people where phone_number_id = ?", $$record{id})
					|| die $self -> db -> simple -> error;

		push @person_record, @{$self -> db -> library -> decode_hashref_list($result -> hashes)};
	}

	$self -> db -> logger -> log(debug => "Initial organization count: @{[scalar @organization_record]}");
	$self -> db -> logger -> log(debug => "Initial person count: @{[scalar @person_record]}");

	# 3: Get unique organizations.

	my(@organization);
	my(%seen);

	for my $org (@organization_record)
	{
		next if ($seen{$$org{organization_id} });

		push @organization, @{$self -> db -> organization -> get_organization_list($user_id, $$org{organization_id})};

		$seen{$$org{organization_id} } = 1;
	}

	# 4: Get unique people.

	%seen = ();

	my(@person);

	for my $person (@person_record)
	{
		next if ($seen{$$person{person_id} });

		push @person, @{$self -> db -> person -> get_person_list($user_id, $$person{person_id})};

		$seen{$$person{person_id} } = 1;
	}

	$self -> db -> logger -> log(debug => "Initial organization count: @{[scalar @organization]}");
	$self -> db -> logger -> log(debug => "Initial person count: @{[scalar @person]}");

	return (\@person, \@organization);

} # End of get_organizations_and_people.

# -----------------------------------------------

sub get_phone_number_id_via_number
{
	my($self, $number) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_id_via_number($number)");

	my($result) = $self -> db -> simple -> query('select id from phone_numbers where number = ?', $number)
					|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_phone_number_id_via_number.

# -----------------------------------------------

sub get_phone_number_id_via_organization
{
	my($self, $organization_id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_id_via_organization($organization_id)");

	my($result) = $self -> db -> simple -> query('select id, phone_number_id from phone_organizations where organization_id = ?', $organization_id)
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_phone_number_id_via_organization.

# -----------------------------------------------

sub get_phone_number_id_via_person
{
	my($self, $person_id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_id_via_person($person_id)");

	my($result) = $self -> db -> simple -> query('select id, phone_number_id from phone_people where person_id = ?', $person_id)
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_phone_number_id_via_person.

# -----------------------------------------------

sub get_phone_number_type_id_via_name
{
	my($self, $name) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_type_id_via_name($name)");

	my($result) = $self -> db -> simple -> query('select id from phone_number_types where name = ?', $name)
					|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_phone_number_id_type_via_name.

# -----------------------------------------------

sub get_phone_number_type_name_via_id
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_type_name_via_id($id)");

	my($result) = $self -> db -> simple -> query('select name from phone_number_types where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# Since we don't use utf8 in menus, so we don't need to call decode('utf', ...).
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || '';

} # End of get_phone_number_type_name_via_id.

# -----------------------------------------------

sub get_phone_number_via_id
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.get_phone_number_via_id($id)");

	my($result) = $self -> db -> simple -> query('select number, phone_number_type_id from phone_numbers where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# list() should never return undef.
	# And list() implies there is just 1 matching record.

	my(@number) = $result -> list;
	my($name)    = $self -> get_phone_number_type_name_via_id($number[1]);

	# Since only 1 field is utf8, we just call decode('utf-8', ...) below,
	# rather than calling $self -> db -> library -> decode_list(...).

	return
	{
		number    => decode('utf-8', $number[0]),
		type_id   => $number[1],
		type_name => $name,
	};

} # End of get_phone_number_via_id.

# --------------------------------------------------

sub save_phone_number_for_organization
{
	my($self, $context, $organization, $count) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.save_phone_number_for_organization($context, ...)");

	my($table_name)               = 'phone_numbers';
	my($phone)                    = {};
	$$phone{number}               = $$organization{"phone_number_$count"};
	$$phone{phone_number_type_id} = $$organization{"phone_number_type_id_$count"};
	$$phone{upper_number}         = uc $$phone{number};
	my($id)                       = $self -> get_phone_number_id_via_number($$phone{number});

	if ($id == 0)
	{
		$id = $self -> db -> library -> insert_hashref_get_id($table_name, $phone);
	}

	$table_name              = 'phone_organizations';
	$phone                   = {};
	$$phone{organization_id} = $$organization{id};
	$$phone{phone_number_id} = $id;

	$self -> db -> simple -> insert($table_name, $phone)
		|| die $self -> db -> simple -> error;

} # End of save_phone_number_for_organization.

# --------------------------------------------------

sub save_phone_number_for_person
{
	my($self, $context, $person, $count) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.save_phone_number_for_person($context, $$person{name}, $count)");

	my($table_name)               = 'phone_numbers';
	my($phone)                    = {};
	$$phone{number}               = $$person{"phone_number_$count"};
	$$phone{phone_number_type_id} = $$person{"phone_number_type_id_$count"};
	$$phone{upper_number}         = uc $$phone{number};
	my($id)                       = $self -> get_phone_number_id_via_number($$phone{number});

	$self -> db -> logger -> log(debug => "Saving phone_number: $$phone{number}");

	if ($id == 0)
	{
		$id = $self -> db -> library -> insert_hashref_get_id($table_name, $phone);
	}

	$table_name              = 'phone_people';
	$phone                   = {};
	$$phone{person_id}       = $$person{id};
	$$phone{phone_number_id} = $id;

	$self -> db -> simple -> insert($table_name, $phone)
		|| die $self -> db -> simple -> error;

} # End of save_phone_number_for_person.

# -----------------------------------------------

sub update_phone_number_type
{
	my($self, $creator_id, $number) = @_;

	$self -> db -> logger -> log(debug => "Database::PhoneNumber.update_phone_number_type($creator_id, ...)");

	my($table_name) = 'phone_numbers';

	$self -> db -> simple -> update($table_name, {phone_number_type_id => $$number{type_id} }, {id => $$number{number_id} })
		|| die $self -> db -> simple -> error;

} # End of update_phone_number_type.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::PhoneNumber - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

This module extends L<App::Office::Contacts::Database::Base>, with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 delete_phone_number_organization($creator_id, $id)

Deletes the database entry linking a phone number to an organization.

=head2 delete_phone_number_person($creator_id, $id)

Deletes the database entry linking a phone number to an person.

=head2 get_organizations_and_people($user_id, $uc_key)

Returns a list of 2 arrayrefs.

The first holds a list of people whose phone numbers match $uc_key.

The second holds a list of organizations whose phone numbers match $uc_key.

=head2 get_phone_number_id_via_number($number)

Returns the id of a phone number.

=head2 get_phone_number_id_via_organization($organization_id)

Returns phone number information for a given organization.

=head2 get_phone_number_id_via_person($person_id)

Returns phone number information for a given person.

=head2 get_phone_number_type_id_via_name($name)

Returns the id of an phone number type.

=head2 get_phone_number_type_name_via_id($id)

Returns an phone number type given its id.

=head2 get_phone_number_via_id($id)

Returns a hashref of phone number information given the id of an phone number. Keys in this hashref:

=over 4

=item o number

The phone number.

=item o type_id

The id of the type of the phone number.

=item o type_name

The name of the type of the phone number.

=back

=head2 save_phone_number_for_organization($context, $organization, $count)

Saves a phone number and which organization it is associated with.

=head2 save_phone_number_for_person($context, $person, $count)

Saves a phone number and which person it is associated with.

=head2 update_phone_number_type($creator_id, $number)

Updates the type of a phone number.

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
