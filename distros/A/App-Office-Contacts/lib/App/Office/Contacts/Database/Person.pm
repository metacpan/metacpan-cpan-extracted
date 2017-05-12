package App::Office::Contacts::Database::Person;

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
	my($self, $person) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.add($$person{name})");

	my($id) = $self -> get_person_id_via_name($$person{name});

	my($result);

	if ($id)
	{
		$result = "'$$person{name}' is already on file. To update, do a search and then click on their name";
	}
	else
	{
		$self -> save_person_transaction('add', $person);

		$result = "Added '$$person{name}'";
	}

	return $result;

} # End of add.

# -----------------------------------------------

sub build_person_record
{
	my($self, $user_id, $people) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.build_person_record($user_id, ...)");

	my(%visibility) = $self -> db -> library -> get_name2id_map('visibilities');
	my($hidden_id)  = $visibility{'No-one'};
	my($result)     = [];

	my($field);
	my($skip);

	for my $person (@$people)
	{
		# Filter out the people whose visibility status is No-one.

		$skip = 0;

		if ($$person{visibility_id} == $hidden_id)
		{
			$skip = 1;
		}

		# Let the user see their own record.

		if ($$person{id} == $user_id)
		{
			$skip = 0;
		}

		# Let the user see records they created.

		if ( ($user_id > 0) && ($$person{creator_id} == $user_id) )
		{
			$skip = 0;
		}

		next if ($skip);

		$field =
		{
			communication_type_id => $$person{communication_type_id},
			facebook_tag          => $$person{facebook_tag},
			gender_id             => $$person{gender_id},
			given_names           => $$person{given_names},
			homepage              => $$person{homepage},
			id                    => $$person{id},
			name                  => $$person{name},
			preferred_name        => $$person{preferred_name},
			role_id               => $$person{role_id},
			surname               => $$person{surname},
			title_id              => $$person{title_id},
			twitter_tag           => $$person{twitter_tag},
			upper_name            => $$person{upper_name},
			visibility_id         => $$person{visibility_id},
		};
		$$field{email_phone} = $self -> get_persons_emails_and_phones($$person{id});
		$$field{occupation}  = $self -> get_persons_occupations($$person{id});

		push @$result, {%$field};
	}

	return $result;

} # End of build_person_record.

# -----------------------------------------------

sub delete
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.delete($id)");

	$self -> db -> simple -> delete('email_people', {person_id => $id});
	$self -> db -> simple -> delete('occupations',  {person_id => $id});
	$self -> db -> simple -> delete('phone_people', {person_id => $id});
	$self -> db -> simple -> delete('spouses',      {person_id => $id});
	$self -> db -> simple -> delete('spouses',      {spouse_id => $id});
	$self -> db -> simple -> delete('people',       {id => $id});

} # End of delete.

# -----------------------------------------------

sub get_people
{
	my($self, $user_id, $uc_key) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_people($user_id, $uc_key)");

	my($result) = $self -> db -> simple -> query("select * from people where upper_name like ? or upper_given_names like ? order by name", "\%$uc_key\%", "\%$uc_key\%")
					|| die $self -> db -> simple -> error;
	$result     = $self -> build_person_record($user_id, $self -> db -> library -> decode_hashref_list($result -> hashes) );

	$self -> db -> logger -> log(debug => "Final people count: @{[scalar @$result]}");

	return $result;

} # End of get_people.

# -----------------------------------------------

sub get_people_for_report
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'Database::Person.get_people_for_report()');

	my($result) = $self -> db -> simple -> query('select * from people')
					|| die $self -> db -> simple -> error;

	return $self -> db -> library -> decode_hashref_list($result -> hashes);

} # End of get_people_for_report.

# -----------------------------------------------

sub get_person_id_via_name
{
	my($self, $name) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_person_id_via_name($name)");

	my($result) = $self -> db -> simple -> query('select id from people where upper_name = ?', uc $name)
					|| die $self -> db -> simple -> error;

	# We don't call decode('utf-8', ...) on integers.
	# And list() implies there is just 1 matching record.

	return ($result -> list)[0] || 0;

} # End of get_person_id_via_name.

# -----------------------------------------------

sub get_person_list
{
	my($self, $user_id, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_person_list($user_id, $id)");

	my($result) = $self -> db -> simple -> query('select name from people where id = ?', $id)
					|| die $self -> db -> simple -> error;

	# Since only 1 field is utf8, we just call decode('utf-8', ...) below,
	# rather than calling $self -> db -> library -> decode_list(...).
	# And list() implies there is just 1 matching record.

	my(@name) = $result -> list;
	my($name) = $name[0] ? decode('utf-8', $name[0]) : '';

	# Filter out people with the same name but the 'wrong' id.

	return $name ? [grep{$$_{id} == $id} @{$self -> get_people($user_id, encode('utf-8', uc $name) )}] : [];

} # End of get_person_list.

# -----------------------------------------------

sub get_person_via_id
{
	my($self, $id) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_person_via_id($id)");

	my($result) = $self -> db -> simple -> query('select * from people where id = ?', $id)
					|| die $self -> db -> simple -> error;
	my($record) = $self -> db -> library -> decode_hashref_list($result -> hash);

	return $$record[0];

} # End of get_person_via_id.

# -----------------------------------------------

sub get_persons_emails_and_phones
{
	my($self, $id)  = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_persons_emails_and_phones($id)");

	my($email_user) = $self -> db -> email_address -> get_email_address_id_via_person($id);
	my($phone_user) = $self -> db -> phone_number -> get_phone_number_id_via_person($id);
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

} # End of get_persons_emails_and_phones.

# -----------------------------------------------

sub get_persons_occupations
{
	my($self, $person_id) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.get_persons_occupations($person_id)");

	my($occupation) = $self -> db -> occupation -> get_occupation_via_person($person_id);
	my($person)     = $self -> get_person_via_id($person_id);

	my(@data);
	my($i);
	my($occ);

	for $i (0 .. $#$occupation)
	{
		$occ = $self -> db -> occupation -> get_occupation_via_id($$occupation[$i]);

		$self -> db -> logger -> log(debug => "occupation_id     => $$occupation[$i]{id}");
		$self -> db -> logger -> log(debug => "occupation_title  => $$occ{occupation_title}");
		$self -> db -> logger -> log(debug => "organization_id   => $$occ{organization_id}");
		$self -> db -> logger -> log(debug => "organization_name => $$occ{organization_name}");
		$self -> db -> logger -> log(debug => "person_id         => $person_id");
		$self -> db -> logger -> log(debug => "person_name       => $$person{name}");

		push @data,
		{
			occupation_id     => $$occupation[$i]{id},
			occupation_title  => $$occ{occupation_title},
			organization_id   => $$occ{organization_id},
			organization_name => $$occ{organization_name},
			person_id         => $person_id,
			person_name       => $$person{name},
		};
	}

	@data = sort
	{
		$$a{organization_name} cmp $$b{organization_name} || $$a{occupation_title} cmp $$b{occupation_title}
	} @data;

	return [@data];

} # End of get_persons_occupations.

# --------------------------------------------------

sub save_person_record
{
	my($self, $context, $person) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.save_person_record($context, $$person{name})");

	my(@field)                = (qw/visibility_id communication_type_id creator_id facebook_tag gender_id given_names homepage name preferred_name role_id surname title_id twitter_tag/);
	my($data)                 = {};
	$$data{$_}                = $$person{$_} for (@field);
	$$data{deleted}           = 0;
	$$data{upper_given_names} = encode('utf-8', uc decode('utf-8', $$data{given_names}) );
	$$data{upper_name}        = encode('utf-8', uc decode('utf-8', $$data{name}) );
	$$data{date_of_birth}     = localstamp; # TODO.
	$$data{timestamp}         = localstamp;
	my($table_name)           = 'people';

	if ($context eq 'add')
	{
		$$person{id} = $$data{id} = $self -> db -> library -> insert_hashref_get_id($table_name, $data);
	}
	else
	{
	 	$self -> db -> simple -> update($table_name, $data, {id => $$person{id} })
			|| die $self -> db -> simple -> error;
	}

} # End of save_person_record.

# --------------------------------------------------

sub save_person_transaction
{
	my($self, $context, $person) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.save_person_transaction($context, $$person{name})");

	# Save person.

	$self -> save_person_record($context, $person);

	# Save email addresses.
	# Phase 1: Get pre-existing email addresses for this person.
	# For a new person there won't be any.

	my($email_people) = $self -> db -> email_address -> get_email_address_id_via_person($$person{id});

	my($address);
	my($id);
	my(%old_address);

	for $id (@$email_people)
	{
		$address                          = $self -> db -> email_address -> get_email_address_via_id($$id{email_address_id});
		$old_address{$$address{address} } =
		{                                         # Table:
			people_id  => $$id{id},               # email_people
			address_id => $$id{email_address_id}, # email_addresses
			type_id    => $$address{type_id},     # email_address_types
			type_name  => $$address{type_name},   # email_address_types
		};
	}

	# Phase 2: Get new data for this person, from the CGI form fields.

	my($count);
	my(%new_address);
	my(%new_type);

	for $count (map{s/email_address_//; $_} grep{/email_address_\d/} sort keys %$person)
	{
		$address = $$person{"email_address_$count"};

		if ($address)
		{
			$new_address{$address} = $count;
			$new_type{$address}    = $$person{"email_address_type_id_$count"};
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

				$self -> db -> email_address -> update_email_address_type($$person{creator_id}, $old_address{$address});
			}
		}
		elsif ($old_address{$address}) # And ! new address.
		{
			# Address has vanished, so delete old address.

			$self -> db -> email_address -> delete_email_address_person($$person{creator_id}, $old_address{$address}{people_id});
		}
		else # ! old address, just new one.
		{
			# Address has appeared, so add new address.

			$self -> db -> email_address -> save_email_address_for_person($context, $person, $new_address{$address});
		}
	}

	# Save phone numbers.
	# Phase 1: Get pre-existing phone numbers for this person.
	# For a new person there won't be any.

	my($phone_people) = $self -> db -> phone_number -> get_phone_number_id_via_person($$person{id});

	my($number);
	my(%old_number);

	for $id (@$phone_people)
	{
		$number                        = $self -> db -> phone_number -> get_phone_number_via_id($$id{phone_number_id});
		$old_number{$$number{number} } =
		{                                       # Table:
			people_id => $$id{id},              # phone_people
			number_id => $$id{phone_number_id}, # phone_numbers
			type_id   => $$number{type_id},     # phone_number_types
			type_name => $$number{type_name},   # phone_number_types
		};
	}

	# Phase 2: Get new data for this person, from the CGI form fields.

	%new_type = ();

	my(%new_number);

	for $count (map{s/phone_number_//; $_} grep{/phone_number_\d/} sort keys %$person)
	{
		$number = $$person{"phone_number_$count"};

		if ($number)
		{
			$new_number{$number} = $count;
			$new_type{$number}   = $$person{"phone_number_type_id_$count"};
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

				$self -> db -> phone_number -> update_phone_number_type($$person{creator_id}, $old_number{$number});
			}
		}
		elsif ($old_number{$number}) # And ! new number.
		{
			# Number has vanished, so delete old number.

			$self -> db -> phone_number -> delete_phone_number_person($$person{creator_id}, $old_number{$number}{people_id});
		}
		else # ! old number, just new one.
		{
			# Number has appeared, so add new number.

			$self -> db -> phone_number -> save_phone_number_for_person($context, $person, $new_number{$number});
		}
	}

} # End of save_person_transaction.

# --------------------------------------------------

sub update
{
	my($self, $person) = @_;

	$self -> db -> logger -> log(debug => "Database::Person.update($$person{name})");

	$self -> save_person_transaction('update', $person);

} # End of update.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Person - A web-based contacts manager

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

=head2 add($person)

Adds $person to the I<people> table.

=head2 build_person_record($user_id, $people)

Returns an arrayref of hashrefs for the given $people. Keys in this hashref are:

=over 4

=item o	communication_type_id

=item o	email_phone

=item o	facebook_tag

=item o	gender_id

=item o	given_names

=item o	homepage

=item o	id

=item o	name

=item o	occupation

=item o	preferred_name

=item o	role_id

=item o	surname

=item o	title_id

=item o	twitter_tag

=item o	upper_name

=item o	visibility_id

=back

=head2 delete($id)

Deletes the person with the given $id from the I<people> table.

=head2 get_people($user_id, $uc_key)

Returns an arrayref of hashrefs (by calling build_person_record() ) of people whose names match
$uc_key.

=head2 get_people_for_report()

Returns an arrayref of hashrefs of people.

=head2 get_person_id_via_name($name)

Returns the id of the person with the given $name.

=head2 get_person_list($user_id, $id)

Returns an arrayref of hashrefs (by calling build_person_record() ) of people whose names are like
the person with the given $id.

=head2 get_person_via_id($id)

Returns the person with the given $id.

=head2 get_persons_emails_and_phones($id)

Returns an arrayref of hashrefs of email addresses and phone numbers for the person with the given $id.

=head2 get_persons_occupations($person_id)

Returns an arrayref of hashrefs of occupations for the given $person_id. Keys in this hashref are:

=over 4

=item o occupation_id

=item o occupation_title

=item o organization_id

=item o organization_name

=item o person_id

=item o person_name

=back

=head2 save_person_record($context, $person)

Saves the given $person to the 'people' table. $context is 'add'.

=head2 save_person_transaction($context, $person)

Saves the given $person and all the email addresses and phone numberes associated with it.

=head2 update($person)

Updates the given $person.

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
