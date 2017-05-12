package App::Office::Contacts::Donations::Database::Donations;

use Moose;

extends 'App::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub add
{
	my($self, $donation, $name) = @_;

	$self -> log(debug => 'Entered add');

	$self -> save_donations_record('add', $donation);

	return "Added donation for '$name'";

} # End of add.

# -----------------------------------------------

sub build_report_by_amount
{
	my($self, $donation, $organizations_table_id, $people_table_id) = @_;

	$self -> log(debug => 'Entered build_report_by_amount');

	my(%donation);
	my($item);
	my($name);
	my(%organization, $organization);
	my(%person, $person);
	my($type);

	for $item (@$donation)
	{
		if ($$item{'table_name_id'} == $organizations_table_id)
		{
			# Get name from cache, if possible.

			if ($organization{$$item{'table_id'} })
			{
				$name = $organization{$$item{'table_id'} };
				$type = 'organization';
			}
			else
			{
				$organization = $self -> db -> organization -> get_organization_via_id($$item{'table_id'});
				$name         = $organization{$$item{'table_id'} } = $$organization{'name'};
				$type         = 'organization';
			}
		}
		else
		{
			# Get name from cache, if possible.

			if ($person{$$item{'table_id'} })
			{
				$name = $person{$$item{'table_id'} };
				$type = 'person';
			}
			else
			{
				$person = $self -> db -> person -> get_person_via_id($$item{'table_id'});
				$name   = $person{$$item{'table_id'} } = $$person{'name'};
				$type   = 'person';
			}
		}

		if (! $donation{$name})
		{
			$donation{$name} =
			{
				amount_input => 0,
				count        => 0,
				type         => $type,
			};
		}

		$donation{$name}{'amount_input'} += $$item{'amount_input'};
		$donation{$name}{'count'}        += 1;
	}

	return \%donation;

} # End of build_report_by_amount.

# -----------------------------------------------

sub build_report_by_date
{
	my($self, $donation, $organizations_table_id, $people_table_id) = @_;

	$self -> log(debug => 'Entered build_report_by_date');

	my(@donation);
	my($item);
	my($name);
	my(%organization, $organization);
	my(%person, $person);

	for $item (@$donation)
	{
		if ($$item{'table_name_id'} == $organizations_table_id)
		{
			# Get name from cache, if possible.

			if ($organization{$$item{'table_id'} })
			{
				$name = $organization{$$item{'table_id'} };
			}
			else
			{
				$organization = $self -> db -> organization -> get_organization_via_id($$item{'table_id'});
				$name         = $organization{$$item{'table_id'} } = $$organization{'name'};
			}
		}
		else
		{
			# Get name from cache, if possible.

			if ($person{$$item{'table_id'} })
			{
				$name = $person{$$item{'table_id'} };
			}
			else
			{
				$person = $self -> db -> person -> get_person_via_id($$item{'table_id'});
				$name   = $person{$$item{'table_id'} } = $$person{'name'};
			}
		}

		push @donation,
		{
			amount_input => $$item{'amount_input'},
			name         => $name,
			timestamp    => $$item{'timestamp'},
		};
	}

	return \@donation;

} # End of build_report_by_date.

# -----------------------------------------------

sub delete
{
	my($self, $entity_type, $table_id, @donation_id) = @_;

	$self -> log(debug => 'Entered delete');

	my($count) = $#donation_id + 1;
	my($sql)   = 'delete from donations where table_id = ? and id in (' . ('?, ') x $#donation_id . '?)';

	$self -> db -> dbh -> do($sql, {}, $table_id, @donation_id);

	return $count;

} # End of delete.

# -----------------------------------------------

sub get_donations_total_report
{
	my($self, $input, $from_date, $to_date, $date_id) = @_;

	$self -> log(debug => 'Entered get_donations_total_report');

	my($donation)               = [$self -> simple -> query('select * from donations') -> hashes];
	my($organizations_table_id) = ${$self -> db -> table_names}{'organizations'};
	my($people_table_id)        = ${$self -> db -> table_names}{'people'};
	my(%report_entity)          = $self -> get_report_entitys;
	my($organization_entity)    = $report_entity{'Organizations'};
	my($people_entity)          = $report_entity{'People'};

	my($broadcast_id);
	my($communication_type_id);
	my($gender_id);
	my($item, @item);
	my(%organization);
	my(%person);
	my($role_id);

	for $item (@$donation)
	{
		# Filter out unwanted records.
		# 1. Does the user just want organizations, or just people, or both?

		if ( ($$input{'report_entity'} == $organization_entity) && ($$item{'table_name_id'} != $organizations_table_id) )
		{
			next;
		}
		elsif ( ($$input{'report_entity'} == $people_entity) && ($$item{'table_name_id'} != $people_table_id) )
		{
			next;
		}

		# Get entity's details in order to answer following questions.

		if ($$item{'table_name_id'} == $organizations_table_id)
		{
			if (! $organization{$$item{'table_id'} })
			{
				$organization{$$item{'table_id'} } = $self -> simple -> query('select broadcast_id, communication_type_id from organizations where id = ?', $$item{'table_id'}) -> hash;
				$broadcast_id                      = $organization{$$item{'table_id'} }{'broadcast_id'};
				$communication_type_id             = $organization{$$item{'table_id'} }{'communication_type_id'};
				$$input{'gender'}                  = 0; # Rig it to match person record.
				$$input{'role'}                    = 0; # Rig it to match person record.
				$gender_id                         = 0;
				$role_id                           = 0;
			}
		}
		else
		{
			if (! $person{$$item{'table_id'} })
			{
				$person{$$item{'table_id'} } = $self -> simple -> query('select broadcast_id, communication_type_id, gender_id, role_id from people where id = ?', $$item{'table_id'}) -> hash;
				$broadcast_id                = $person{$$item{'table_id'} }{'broadcast_id'};
				$communication_type_id       = $person{$$item{'table_id'} }{'communication_type_id'};
				$gender_id                   = $person{$$item{'table_id'} }{'gender_id'};
				$role_id                     = $person{$$item{'table_id'} }{'role_id'};
			}
		}

		# 2. Does the user just want entities with a specific broadcast?

		if ( (! $$input{'ignore_broadcast'}) && ($$input{'broadcast'} != $broadcast_id) )
		{
			next;
		}

		# 3. Does the user just want entities with a specific communication_type?

		if ( (! $$input{'ignore_communication_type'}) && ($$input{'communication_type'} != $communication_type_id) )
		{
			next;
		}

		# 4. Does the user just want entities or people with a specific gender?

		if ( (! $$input{'ignore_gender'}) && ($$input{'gender'} != $gender_id) )
		{
			next;
		}

		# 5. Does the user just want entities with a specific role?

		if ( (! $$input{'ignore_role'}) && ($$input{'role'} != $role_id) )
		{
			next;
		}

		# 6. Does the user just want entities in a specific date range?

		if ( (! $$input{'ignore_date'}) && ($$item{'timestamp'} lt $from_date) || ($$item{'timestamp'} gt $to_date) )
		{
			next;
		}

		push @item, $item;
	}

	my($result);

	if ($$input{'report_id'} == $date_id)
	{
		# Warning. This returns an array ref.

		$result = $self -> build_report_by_date(\@item, $organizations_table_id, $people_table_id);
	}
	else
	{
		# Warning. This returns a hash ref.

		$result = $self -> build_report_by_amount(\@item, $organizations_table_id, $people_table_id);
	}

	return $result;

} # End of get_donations_total_report.

# -----------------------------------------------

sub get_donations
{
	my($self, $table_name, $table_id) = @_;

	$self -> log(debug => 'Entered get_donations');

	my($table_map)   = $self -> db -> util -> table_map;
	my($table_entry) = $$table_map{$table_name};

	return $self -> db -> dbh -> selectall_arrayref('select * from donations where table_name_id = ? and table_id = ? order by timestamp desc', {Slice => {} }, $$table_entry{'id'}, $table_id) || [];

} # End of get_donations.

# --------------------------------------------------

sub save_donations_record
{
	my($self, $context, $donation) = @_;

	$self -> log(debug => 'Entered save_donations_record');

	my($table_name) = 'donations';
	my(@field)      = (qw/amount_input amount_local creator_id currency_id_1 currency_id_2 donation_motive_id donation_project_id table_id table_name_id motive_text project_text/);
	my($data)       = {};
	my(%id)         =
	(
	 creator    => 1,
	 person     => 1,
	 table      => 1,
	 table_name => 1,
	);

	my($field_name);

	for (@field)
	{
		if ($id{$_})
		{
			$field_name = "${_}_id";
		}
		else
		{
			$field_name = $_;
		}

		$$data{$field_name} = $$donation{$_};
	}

	if ($context eq 'add')
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $data);

		$$donation{'id'} = $$data{'id'} = $self -> db -> util -> last_insert_id($table_name);
	}
	else
	{
	 	$self -> db -> dbh -> do("update $table_name set where id = $$donation{'id'}", $data);
	}

} # End of save_donations_record.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
