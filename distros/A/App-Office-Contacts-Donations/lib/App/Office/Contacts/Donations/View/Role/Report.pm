package App::Office::Contacts::Donations::View::Role::Report;

use JSON::XS;

use Moose::Role;

our $VERSION = '1.10';

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
				amount => 0,
				number => 0,
				type   => $type,
			};
		}

		$donation{$name}{'amount'} += $$item{'amount_input'};
		$donation{$name}{'number'} += 1;
		$donation{$name}{'type'}   = $type;
	}

	return {%donation};

} # End of build_report_by_amount.

# -----------------------------------------------

sub build_report_by_date
{
	my($self, $donation, $organizations_table_id, $people_table_id) = @_;

	$self -> log(debug => 'Entered build_report_by_amount');

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
			amount    => $$item{'amount_input'},
			name      => $name,
			timestamp => $$item{'timestamp'},
		};
	}

	return [@donation];

} # End of build_report_by_date.

# -----------------------------------------------

sub generate_donation_total_report
{
	my($self, $user_data, $report_name) = @_;

	$self -> log(debug => 'Entered generate_donation_total_report');

	my($input) = {};

	if ($user_data -> success)
	{
		for my $field_name ($user_data -> valids)
		{
			$$input{$field_name} = $user_data -> get_value($field_name) || '';
		}
	}
	else
	{
		return {error => {type => 'Invalid report options'} };
	}

	my($from_date, $to_date)    = $self -> validate_date_range($$input{'date_range'});
	my($donation)               = $self -> db -> dbh -> selectall_arrayref('select * from donations', {Slice => {} }) || [];
	my($organizations_table_id) = ${$self -> db -> util -> table_map}{'organizations'}{'id'};
	my($people_table_id)        = ${$self -> db -> util -> table_map}{'people'}{'id'};
	my($report_entity)          = $self -> db -> util -> get_report_entities;
	my($organization_entity)    = $$report_entity{'Organizations'};
	my($people_entity)          = $$report_entity{'People'};

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

		if ( ($$input{'report_entity_id'} == $organization_entity) && ($$item{'table_name_id'} != $organizations_table_id) )
		{
			next;
		}
		elsif ( ($$input{'report_entity_id'} == $people_entity) && ($$item{'table_name_id'} != $people_table_id) )
		{
			next;
		}

		# Get entity's details in order to answer following questions.

		if ($$item{'table_name_id'} == $organizations_table_id)
		{
			if (! $organization{$$item{'table_id'} })
			{
				$organization{$$item{'table_id'} } = $self -> db -> dbh -> selectrow_hashref('select broadcast_id, communication_type_id from organizations where id = ?', undef, $$item{'table_id'});
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
				$person{$$item{'table_id'} } = $self -> db -> dbh -> selectrow_hashref('select broadcast_id, communication_type_id, gender_id, role_id from people where id = ?', undef, $$item{'table_id'});
				$broadcast_id                = $person{$$item{'table_id'} }{'broadcast_id'};
				$communication_type_id       = $person{$$item{'table_id'} }{'communication_type_id'};
				$gender_id                   = $person{$$item{'table_id'} }{'gender_id'};
				$role_id                     = $person{$$item{'table_id'} }{'role_id'};
			}
		}

		# 2. Does the user just want entities with a specific broadcast?

		if ( (! $$input{'ignore_broadcast'}) && ($$input{'broadcast_id'} != $broadcast_id) )
		{
			next;
		}

		# 3. Does the user just want entities with a specific communication_type?

		if ( (! $$input{'ignore_communication_type'}) && ($$input{'communication_type_id'} != $communication_type_id) )
		{
			next;
		}

		# 4. Does the user just want entities or people with a specific gender?

		if ( (! $$input{'ignore_gender'}) && ($$input{'gender_id'} != $gender_id) )
		{
			next;
		}

		# 5. Does the user just want entities with a specific role?

		if ( (! $$input{'ignore_role'}) && ($$input{'role_id'} != $role_id) )
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

	if ($report_name eq 'Donations_by_date')
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

} # End of generate_donation_total_report.

# -----------------------------------------------

sub validate_date_range
{
	my($self, $date_range) = @_;
	my($today)     = Date::Simple::today();
	my(@ymd)       = $today -> as_ymd();
	$ymd[2]        = 1;
	my($first_day) = Date::Simple::ymd(@ymd);
	my($day_count) = Date::Simple::days_in_month($ymd[0], $ymd[1]);
	$ymd[2]        = $day_count;
	my($last_day)  = Date::Simple::ymd(@ymd);
	$date_range    = '' if (! $date_range);

	my(@field);

	if ($date_range =~ /(\d{4}-\d{1,2}-\d{1,2})\.(\d{4}-\d{1,2}-\d{1,2})/)
	{
		$field[0] = $1;
		$field[1] = $2;
	}

	my($from_date) = Date::Simple::date($field[0]) || $first_day;
	my($to_date)   = Date::Simple::date($field[1]) || $last_day;
	$from_date     = $self -> validate_digit_count($from_date);
	$to_date       = $self -> validate_digit_count($to_date);

	return ("$from_date 00:00:00", "$to_date 23:59:59");

} # End of validate_date_range.

# -----------------------------------------------
# Javascript returns the 1st December as 2008-12-1, not -01.

sub validate_digit_count
{
	my($self, $date) = @_;
	my(@ymd) = split(/-/, $date);
	$ymd[1]  = "0$ymd[1]" if (length($ymd[1]) == 1);
	$ymd[2]  = "0$ymd[2]" if (length($ymd[2]) == 1);

	return "$ymd[0]-$ymd[1]-$ymd[2]";

} # End of validate_digit_count.

# -----------------------------------------------

no Moose::Role;

1;
