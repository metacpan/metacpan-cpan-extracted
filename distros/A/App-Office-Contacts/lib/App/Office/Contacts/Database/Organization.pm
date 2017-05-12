package App::Office::Contacts::Database::Organization;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For decode().

use Moo;

use Time::Stamp -stamps => {dt_sep => ' ', us => 1}; # For localstamp.

use Unicode::Collate;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# --------------------------------------------------

sub add
{
	my($self, $organization) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.add($$organization{name})");

	my($id) = $self -> get_organization_id_via_name($$organization{name});

	my($result);

	if ($id)
	{
		$result = "'$$organization{name}' is already on file. To update, do a search and then click on its name";
	}
	else
	{
		$self -> save_organization_transaction('add', $organization);

		$result = "Added '$$organization{name}'";
	}

	return $result;

} # End of add.

# -----------------------------------------------

sub build_organization_record
{
	my($self, $user_id, $organizations) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.build_organization_record($user_id, ...)");

	my(%visibility) = $self -> db -> library -> get_name2id_map('visibilities');
	my($hidden_id)  = $visibility{'No-one'};
	my($result)     = [];

	my($field);
	my($skip);

	for my $organization (@$organizations)
	{
		# Filter out the organizations whose visibility status is No-one.

		$skip = 0;

		if ($$organization{visibility_id} == $hidden_id)
		{
			$skip = 1;
		}

		# Let the user see records they created.

		if ( ($user_id > 0) && ($$organization{creator_id} == $user_id) )
		{
			$skip = 0;
		}

		next if ($skip);

		$field  =
		{
			communication_type_id => $$organization{communication_type_id},
			facebook_tag          => $$organization{facebook_tag},
			homepage              => $$organization{homepage},
			id                    => $$organization{id},
			name                  => $$organization{name},
			role_id               => $$organization{role_id},
			twitter_tag           => $$organization{twitter_tag},
			visibility_id         => $$organization{visibility_id},
		};
		$$field{email_phone} = $self -> get_organizations_emails_and_phones($$organization{id});
		$$field{staff}       = $self -> get_organizations_staff($$organization{id});

		push @$result, {%$field};
	}

	return $result;

} # End of build_organization_record.

# -----------------------------------------------

sub delete
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.delete($id)");

	my($response);

	if ($id == 1)
	{
		$response = "Error: You cannot delete the special company called '-'";
	}
	else
	{
		$self -> db -> simple -> delete('email_organizations', {organization_id => $id});
		$self -> db -> simple -> delete('occupations',         {organization_id => $id});
		$self -> db -> simple -> delete('phone_organizations', {organization_id => $id});
		$self -> db -> simple -> delete('organizations',       {id => $id});

		$response = 'Deleted organization';
	}

	return $response;

} # End of delete.

# -----------------------------------------------

sub get_organization_id_via_name
{
	my($self, $name) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organization_id_via_name($name)");

	my($result) = $self -> db -> simple -> query('select id from organizations where upper_name = ?', uc $name)
		|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_organization_id_via_name.

# -----------------------------------------------

sub get_organization_list
{
	my($self, $user_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organization_list($user_id, $id)");

	my($name) = $self -> get_organization_name($id);

	return $name ? $self -> get_organizations($user_id, encode('utf-8', uc $name) ) : [];

} # End of get_organization_list.

# -----------------------------------------------

sub get_organization_name
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organization_name($id)");

	my($result) = $self -> db -> simple -> query("select name from organizations where id = ?", $id)
					|| die $self -> db -> simple -> error;

	# And list() implies there is just 1 matching record.

	my(@name) = $result -> list;

	# Since only 1 field is utf8, we just call decode('utf-8', ...) below,
	# rather than calling $self -> db -> library -> decode_list(...).

	return $name[0] ? decode('utf-8', $name[0]) : '';

} # End of get_organization_name.

# -----------------------------------------------

sub get_organizations
{
	my($self, $user_id, $uc_key) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organizations($user_id, $uc_key)");

	my($result) = $self -> db -> simple -> query("select * from organizations where upper_name like ? order by name", "%$uc_key%")
				|| die $self -> db -> simple -> error;
	$result     = $self -> build_organization_record($user_id, $self -> db -> library -> decode_hashref_list($result -> hashes) );

	$self -> db -> logger -> log(debug => "Final org count: @{[scalar @$result]}");

	return $result;

} # End of get_organizations.

# -----------------------------------------------

sub get_organizations_emails_and_phones
{
	my($self, $id)  = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organizations_emails_and_phones($id)");

	my($email_user) = $self -> db -> email_address -> get_email_address_id_via_organization($id);
	my($phone_user) = $self -> db -> phone_number -> get_phone_number_id_via_organization($id);
	my($max)        = ($#$email_user > $#$phone_user) ? $#$email_user : $#$phone_user;

	my(@data);
	my($email_address);
	my($i);
	my($phone_number);

	for $i (0 .. $max)
	{
		if ($i <= $#$email_user)
		{
			$email_address = $self -> db -> email_address -> get_email_address_via_id($$email_user[$i]{email_address_id});
		}
		else
		{
			$email_address = {address => '', type_id => 0, type_name => ''};
		}

		if ($i <= $#$phone_user)
		{
			$phone_number = $self -> db -> phone_number -> get_phone_number_via_id($$phone_user[$i]{phone_number_id});
		}
		else
		{
			$phone_number = {number => '', type_id => 0, type_name => ''};
		}

		push @data,
		{
			email =>
			{
				address   => $$email_address{address},
				type_id   => $$email_address{type_id},
				type_name => $$email_address{type_name},
			},
			phone =>
			{
				number    => $$phone_number{number},
				type_id   => $$phone_number{type_id},
				type_name => $$phone_number{type_name},
			},
		};
	}

	if ($#data < 0)
	{
		$data[0] =
		{
			email =>
			{
				address   => '',
				type_id   => 0,
				type_name => '',
			},
			phone =>
			{
				number    => '',
				type_id   => 0,
				type_name => '',
			},
		};
	}

	return [@data];

} # End of get_organizations_emails_and_phones.

# -----------------------------------------------

sub get_organizations_for_report
{
	my($self, $name) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.get_organizations_for_report($name)");

	my($result) = $self -> db -> simple -> query('select * from organizations where upper_name != ?', uc $name)
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_organizations_for_report.

# -----------------------------------------------

sub get_organizations_staff
{
	my($self, $organization_id) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_organizations_staff($organization_id)");

	my($occupation) = $self -> db -> occupation -> get_occupation_via_organization($organization_id);

	my(@data);
	my($i);
	my($occ);
	my($person_id, %person);

	for $i (0 .. $#$occupation)
	{
		$occ                = $self -> db -> occupation -> get_occupation_via_id($$occupation[$i]);
		$person_id          = $$occ{person_id};
		$person{$person_id} = $self -> db -> person -> get_person_via_id($person_id) if (! $person{$person_id});

		push @data,
		{
			occupation_id    => $$occupation[$i]{id},
			occupation_title => $$occ{occupation_title},
			person_id        => $person_id,
			person_name      => $person{$person_id}{name},
		};
	}

	@data = sort
	{
		$$a{person_name} cmp $$b{person_name} || $$a{occupation_title} cmp $$b{occupation_title}
	} @data;

	return [@data];

} # End of get_organizations_staff.

# --------------------------------------------------

sub save_organization_record
{
	my($self, $context, $organization) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.save_organization_record($context, ...)");

	my(@field)         = (qw/visibility_id communication_type_id creator_id facebook_tag homepage name role_id twitter_tag/);
	my($data)          = {};
	$$data{$_}         = $$organization{$_} for (@field);
	$$data{deleted}    = 0;
	$$data{timestamp}  = localstamp;
	$$data{upper_name} = encode('utf-8', uc decode('utf-8', $$data{name}) );
	my($table_name)    = 'organizations';

	if ($context eq 'add')
	{
		$$organization{id} = $$data{id} = $self -> db -> library -> insert_hashref_get_id($table_name, $data);
	}
	else
	{
	 	$self -> db -> simple -> update($table_name, $data, {id => $$organization{id} })
			|| die $self -> db -> simple -> error;
	}

} # End of save_organization_record.

# --------------------------------------------------

sub save_organization_transaction
{
	my($self, $context, $organization) = @_;

	$self -> db -> logger -> log(debug => "Database::Org.save_organization_transaction($context, ...)");

	# Save organization.

	$self -> save_organization_record($context, $organization);

	# Save email addresses.
	# Phase 1: Get pre-existing email addresses for this person.
	# For a new person there won't be any.

	my($email_organization) = $self -> db -> email_address -> get_email_address_id_via_organization($$organization{id});

	my($address);
	my($id);
	my(%old_address);

	for $id (@$email_organization)
	{
		$address                          = $self -> db -> email_address -> get_email_address_via_id($$id{email_address_id});
		$old_address{$$address{address} } =
		{                                               # Table:
			organization_id  => $$id{id},               # email_organizations
			address_id       => $$id{email_address_id}, # email_addresses
			type_id          => $$address{type_id},     # email_address_types
			type_name        => $$address{type_name},   # email_address_types
		};
	}

	# Phase 2: Get new data for this person, from the CGI form fields.

	my($count);
	my(%new_address);
	my(%new_type);

	for $count (map{s/email_address_//; $_} grep{/email_address_\d/} sort keys %$organization)
	{
		$address = $$organization{"email_address_$count"};

		if ($address)
		{
			$new_address{$address} = $count;
			$new_type{$address}    = $$organization{"email_address_type_id_$count"};
		}
	}

	# Phase 3: Combine old and new email addresses but avoid duplications.

	my(%address) = (%old_address, %new_address);

	for $address (keys %address)
	{
		if ($old_address{$address} && $new_address{$address})
		{
			# The email address type might have changed.

			if ($old_address{$address}{type_id} != $new_type{$address})
			{
				$old_address{$address}{type_id} = $new_type{$address};

				$self -> db -> email_address -> update_email_address_type($$organization{creator_id}, $old_address{$address});
			}
		}
		elsif ($old_address{$address}) # And ! new address.
		{
			# Address has vanished, so delete old address.

			$self -> db -> email_address -> delete_email_address_organization($$organization{creator_id}, $old_address{$address}{organization_id});
		}
		else # ! old address, just new one.
		{
			# Address has appeared, so add new address.

			$self -> db -> email_address -> save_email_address_for_organization($context, $organization, $new_address{$address});
		}
	}

	# Save phone numbers.
	# Phase 1: Get pre-existing phone numbers for this person.
	# For a new person there won't be any.

	my($phone_organization) = $self -> db -> phone_number -> get_phone_number_id_via_organization($$organization{id});

	my($number);
	my(%old_number);

	for $id (@$phone_organization)
	{
		$number                        = $self -> db -> phone_number -> get_phone_number_via_id($$id{phone_number_id});
		$old_number{$$number{number} } =
		{                                             # Table:
			organization_id => $$id{id},              # phone_organizations
			number_id       => $$id{phone_number_id}, # phone_numbers
			type_id         => $$number{type_id},     # phone_number_types
			type_name       => $$number{type_name},   # phone_number_types
		};
	}

	# Phase 2: Get new data for this person, from the CGI form fields.

	%new_type = ();

	my(%new_number);

	for $count (map{s/phone_number_//; $_} grep{/phone_number_\d/} sort keys %$organization)
	{
		$number = $$organization{"phone_number_$count"};

		if ($number)
		{
			$new_number{$number} = $count;
			$new_type{$number}   = $$organization{"phone_number_type_id_$count"};
		}
	}

	# Phase 3: Combine old and new phone numbers but avoid duplications.

	my(%number) = (%old_number, %new_number);

	for $number (keys %number)
	{
		if ($old_number{$number} && $new_number{$number})
		{
			# The phone number type might have changed.

			if ($old_number{$number}{type_id} != $new_type{$number})
			{
				$old_number{$number}{type_id} = $new_type{$number};

				$self -> db -> phone_number -> update_phone_number_type($$organization{creator_id}, $old_number{$number});
			}
		}
		elsif ($old_number{$number}) # And ! new number.
		{
			# Number has vanished, so delete old number.

			$self -> db -> phone_number -> delete_phone_number_organization($$organization{creator_id}, $old_number{$number}{organization_id});
		}
		else # ! old number, just new one.
		{
			# Number has appeared, so add new number.

			$self -> db -> phone_number -> save_phone_number_for_organization($context, $organization, $new_number{$number});
		}
	}

} # End of save_organization_transaction.

# --------------------------------------------------

sub update
{
	my($self, $organization) = @_;

	$self -> db -> logger -> log(debug => 'Database::Org.update(...)');

	my($result);

	# Special code for id == 1.

	if ($$organization{id} <= 1)
	{
		$result = "Error: You cannot update the special company called '-'";
	}
	else
	{
		$self -> save_organization_transaction('update', $organization);

		$result = "Updated '$$organization{name}'";
	}

	return $result;

} # End of update.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Organization - A web-based contacts manager

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

=head2 add($organization)

Adds $organization to the I<organizations> table.

=head2 build_organization_record($user_id, $organizations)

Returns an arrayref of hashrefs for the given $organizations. Keys in this hashref are:

=over 4

=item o communication_type_id

=item o email_phone

=item o facebook_tag

=item o homepage

=item o id

=item o name

=item o role_id

=item o staff

=item o twitter_tag

=item o visibility_id

=back

=head2 delete($id)

Deletes the organization with the given $id from the I<organizations> table.

=head2 get_organization_id_via_name($name)

Returns the id of the organization with the given $name.

=head2 get_organization_list($user_id, $id)

Returns an arrayref of hashrefs (by calling build_organization_record() ) of organizations whose names are like
the organization with the given $id.

=head2 get_organization_name($id)

Returns the name of the organization with the given $name.

=head2 get_organizations($user_id, $uc_key)

Returns an arrayref of hashrefs (by calling build_organization_record() ) of organizations whose names match
$uc_key.

=head2 get_organizations_emails_and_phones($id)

Returns an arrayref of hashrefs of email addresses and phone numbers for the organization with the given $id.

=head2 get_organizations_for_report($name)

Returns an arrayref of hashrefs of organizations whose names match $name.

=head2 get_organizations_staff($organization_id)

Returns an arrayref of hashrefs of staff for the given $organization_id. Keys in this hashref are:

=over 4

=item o occupation_id

=item o occupation_title

=item o person_id

=item o person_name

=back

=head2 save_organization_record($context, $organization)

Saves the given $organization to the 'organizations' table. $context is 'add'.

=head2 save_organization_transaction($context, $organization)

Saves the given $organization and all the email addresses and phone numberes associated with it.

=head2 update($organization)

Updates the given $organization.

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
