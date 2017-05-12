package App::Office::Contacts::Database::EmailAddress;

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

sub delete_email_address_organization
{
	my($self, $creator_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.delete_email_address_organization($creator_id, $id)");

	$self -> db -> simple -> delete('email_organizations', {id => $id})
		|| die $self -> db -> simple -> error;

} # End of delete_email_address_organization.

# -----------------------------------------------

sub delete_email_address_person
{
	my($self, $creator_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.delete_email_address_people($creator_id, $id)");

	$self -> db -> simple -> delete('email_people', {id => $id})
		|| die $self -> db -> simple -> error;

} # End of delete_email_address_people.

# -----------------------------------------------

sub get_email_address_id_via_address
{
	my($self, $address) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_id_via_address($address)");

	my($result) = $self -> db -> simple -> query('select id from email_addresses where address = ?', $address)
					|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_email_address_id_via_address.

# -----------------------------------------------

sub get_email_address_id_via_organization
{
	my($self, $organization_id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_id_via_organization($organization_id)");

	my($result) = $self -> db -> simple -> query('select id, email_address_id from email_organizations where organization_id = ?', $organization_id)
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_email_address_id_via_organization.

# -----------------------------------------------

sub get_email_address_id_via_person
{
	my($self, $person_id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_id_via_person($person_id)");

	my($result) = $self -> db -> simple -> query('select id, email_address_id from email_people where person_id = ?', $person_id)
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_email_address_id_via_person.

# -----------------------------------------------

sub get_email_address_type_id_via_name
{
	my($self, $name) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_type_id_via_name($name)");

	my($result) = $self -> db -> simple -> query('select id from email_address_types where name = ?', $name)
					|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_email_address_type_id_via_name.

# -----------------------------------------------

sub get_email_address_type_name_via_id
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_type_name_via_id($id)");

	my($result) = $self -> db -> simple -> query('select name from email_address_types where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# Since we don't use utf8 in menus, so we don't need to call decode('utf-8', ...).
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || '';

} # End of get_email_address_type_name_via_id.

# -----------------------------------------------

sub get_email_address_via_id
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_email_address_via_id($id)");

	my($result) = $self -> db -> simple -> query('select address, email_address_type_id from email_addresses where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# list() should never return undef.
	# And list() implies there is just 1 matching record.

	my(@address) = $result -> list;
	my($name)    = $self -> get_email_address_type_name_via_id($address[1]);

	# Since only 1 field is utf8, we just call decode('utf-8', ...) below,
	# rather than calling $self -> db -> library -> decode_list(...).

	return
	{
		address   => decode('utf-8', $address[0]),
		type_id   => $address[1],
		type_name => $name,
	};

} # End of get_email_address_via_id.

# -----------------------------------------------

sub get_organizations_and_people
{
	my($self, $user_id, $uc_key) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.get_organizations_and_people($user_id, $uc_key)");

	# 1: Get email addresses.

	my($result) = $self -> db -> simple -> query("select * from email_addresses where upper_address like ?", "%$uc_key%")
					|| die $self -> db -> simple -> error;

	# 2: Get org ids and people ids.

	my(@organization_record);
	my(@person_record);

	for my $record (@{$self -> db -> library -> decode_hashref_list($result -> hashes)})
	{
		$result = $self -> db -> simple -> query("select * from email_organizations where email_address_id = ?", $$record{id})
					|| die $self -> db -> simple -> error;

		push @organization_record, @{$self -> db -> library -> decode_hashref_list($result -> hashes)};

		$result = $self -> db -> simple -> query("select * from email_people where email_address_id = ?", $$record{id})
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

# --------------------------------------------------

sub save_email_address_for_organization
{
	my($self, $context, $organization, $count) = @_;

	$self -> db -> logger -> log(debug => 'Database::EmailAddress.save_email_address_for_organization(...)');

	my($table_name)                = 'email_addresses';
	my($email)                     = {};
	$$email{address}               = $$organization{"email_address_$count"};
	$$email{email_address_type_id} = $$organization{"email_address_type_id_$count"};
	$$email{upper_address}         = uc $$email{address};
	my($id)                        = $self -> get_email_address_id_via_address($$email{address});

	if ($id == 0)
	{
		$id = $self -> db -> library -> insert_hashref_get_id($table_name, $email);
	}

	$table_name               = 'email_organizations';
	$email                    = {};
	$$email{email_address_id} = $id;
	$$email{organization_id}  = $$organization{id};

	$self -> db -> simple -> insert($table_name, $email)
		|| die $self -> db -> simple -> error;

} # End of save_email_address_for_organization.

# --------------------------------------------------

sub save_email_address_for_person
{
	my($self, $context, $person, $count) = @_;

	$self -> db -> logger -> log(debug => 'Database::EmailAddress.save_email_address_for_person(...)');

	my($table_name)                = 'email_addresses';
	my($email)                     = {};
	$$email{address}               = $$person{"email_address_$count"};
	$$email{email_address_type_id} = $$person{"email_address_type_id_$count"};
	$$email{upper_address}         = uc $$email{address};
	my($id)                        = $self -> get_email_address_id_via_address($$email{address});

	$self -> db -> logger -> log(debug => "Saving email_address: $$email{address}");

	if ($id == 0)
	{
		$id = $self -> db -> library -> insert_hashref_get_id($table_name, $email);
	}

	$table_name               = 'email_people';
	$email                    = {};
	$$email{email_address_id} = $id;
	$$email{person_id}        = $$person{id};

	$self -> db -> simple -> insert($table_name, $email)
		|| die $self -> db -> simple -> error;

} # End of save_email_address_for_person.

# -----------------------------------------------

sub update_email_address_type
{
	my($self, $creator_id, $address) = @_;

	$self -> db -> logger -> log(debug => "Database::EmailAddress.update_email_address_type($creator_id, ...)");

	my($table_name) = 'email_addresses';

	$self -> db -> simple -> update($table_name, {email_address_type_id => $$address{type_id} }, {id => $$address{address_id} })
		|| die $self -> db -> simple -> error;

} # End of update_email_address_type.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::EmailAddress - A web-based contacts manager

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

=head2 delete_email_address_organization($creator_id, $id)

Deletes the database entry linking an email address to an organization.

=head2 delete_email_address_person($creator_id, $id)

Deletes the database entry linking an email address to a person.

=head2 get_email_address_id_via_address($address)

Returns the id of an email address.

=head2 get_email_address_id_via_organization($organization_id)

Returns email address information for a given organization.

=head2 get_email_address_id_via_person($person_id)

Returns email address information for a given person.

=head2 get_email_address_type_id_via_name($name)

Returns the id of an email address type.

=head2 get_email_address_type_name_via_id($id)

Returns an email address type given its id.

=head2 get_email_address_via_id($id)

Returns a hashref of email address information given the id of an email address. Keys in this hashref:

=over 4

=item o address

The email address.

=item o type_id

The id of the type of the email address.

=item o type_name

The name of the type of the email address.

=back

=head2 get_organizations_and_people($user_id, $uc_key)

Returns a list of 2 arrayrefs.

The first holds a list of people whose email addresses match $uc_key.

The second holds a list of organizations whose email addresses match $uc_key.

=head2 save_email_address_for_organization($context, $organization, $count)

Saves an email address and which organization it is associated with.

=head2 save_email_address_for_person($context, $person, $count)

Saves an email address and which person it is associated with.

=head2 update_email_address_type($creator_id, $address)

Updates the type of an email address.

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
