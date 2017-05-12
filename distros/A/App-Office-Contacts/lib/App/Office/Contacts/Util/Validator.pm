package App::Office::Contacts::Util::Validator;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Verifier;

use Moo;

has app =>
(
	default  => sub{return ''},
	is       => 'ro',
	#isa     => 'App::Office::Contacts::Controller::Exporter::Person', etc,
	required => 1,
);

has config =>
(
	default  => sub{return {} },
	is       => 'ro',
	#isa     => 'HashRef',
	required => 1,
);

has db =>
(
	default  => sub{return ''},
	is       => 'ro',
	#isa     => 'App::Office::Contacts::Database',
	required => 1,
);

has query =>
(
	default  => sub{return ''},
	is       => 'ro',
	#isa     => 'Any',
	required => 1,
);

our $VERSION = '2.04';

# --------------------------------------------------

sub add_note
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.add_note()');

	my($max_note_length) = ${$self -> config}{max_note_length};
	my($verifier)        = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			entity_id =>
			{
				post_check => sub {return $self -> check_entity_id(shift)},
				required   => 1,
				type       => 'Int',
			},
			entity_type =>
			{
				post_check => sub {return shift -> get_value('entity_type') =~ /^(?:organizations|people)/ ? 1 : 0},
				required   => 1,
				type       => 'Str',
			},
			body =>
			{
				# We can't call clean_user_data() as a filter here,
				# because we need to pass in the max length,
				# and we can't call it as a post_check, since it
				# returns the clean data, not an error flag.
				max_length => $max_note_length,
				min_length => 1,
				required   => 1,
				type       => 'Str',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of add_note.

# --------------------------------------------------

sub add_occupation
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.add_occupation()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			occupation_title =>
			{
				max_length => 250,
				# We can't use a post_check because the occ title might not be on file yet.
				# post_check => sub {return $self -> db -> library -> validate_id('occupation_titles', shift -> get_value('occupation_title') )},
				required   => 1,
				type       => 'Str',
			},
			organization_name =>
			{
				max_length => 250,
				post_check => sub {return $self -> db -> library -> validate_name('organizations', shift -> get_value('organization_name') )},
				required   => 1,
				type       => 'Str',
			},
			person_id =>
			{
				post_check => sub {return $self -> check_person_id(shift -> get_value('person_id') )},
				required   => 1,
				type       => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of add_occupation.

# --------------------------------------------------

sub add_organization
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.add_organization()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			%{$self -> organization_profile},
			name =>
			{
				post_check => sub {return $self -> check_organization_name(shift -> get_value('name') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of add_organization.

# --------------------------------------------------

sub add_person
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.add_person()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			%{$self -> person_profile},
			name =>
			{
				post_check => sub {return $self -> check_person_name(shift -> get_value('name') )},
				required   => 1,
				type       => 'Str',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of add_person.

# --------------------------------------------------

sub add_staff
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.add_staff()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			occupation_title =>
			{
				max_length => 250,
				# We can't use a post_check because the occ title might not be on file yet.
				# post_check => sub {return $self -> db -> library -> validate_id('occupation_titles', shift -> get_value('occupation_title') )},
				required   => 1,
				type       => 'Str',
			},
			organization_id =>
			{
				post_check => sub {return $self -> check_organization_id(shift -> get_value('organization_id') )},
				required   => 1,
				type       => 'Int',
			},
			person_name =>
			{
				max_length => 250,
				post_check => sub {return $self -> db -> library -> validate_name('people', shift -> get_value('person_name') )},
				required   => 1,
				type       => 'Str',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of add_staff.

# -----------------------------------------------

sub check_entity_id
{
	my($self, $result) = @_;
	my($entity_id)   = $result -> get_value('entity_id');
	my($entity_type) = $result -> get_value('entity_type');

	return $entity_type eq 'organizations' # Expect table name.
		? $self -> check_organization_id($entity_id)
		: $entity_type eq 'people'
		? $self -> check_person_id($entity_id)
		: die "Error: Unknown entity type: '$entity_type'\n";

} # End of check_entity_id.

# -----------------------------------------------

sub check_organization_id
{
	my($self, $organization_id) = @_; # Note: A max length of 10 is arbitrary.
	$organization_id = clean_user_data($organization_id, 10, 1);
	my($expected_id) = $self -> db -> session -> param('organization_id') || 0;
	my($message)     = "Error: Organization id is '$organization_id' but in the session it's '$expected_id'\n";

	die $message if (! $expected_id);

	my($org_id) = $self -> db -> library -> validate_id('organizations', $organization_id);

	die "Error: Organization id is '$organization_id' but this is not on file\n" if ($org_id == 0);
	die $message if ($organization_id != $expected_id);

	# Return 1 for success as expected by Data::Verifier.

	return 1;

} # End of check_organization_id.

# -----------------------------------------------

sub check_organization_name
{
	my($self, $name) = @_;

	die "That organization is already on file\n" if ($self -> db -> library -> validate_name('organizations', $name) > 0);

	# Return 1 for success as expected by Data::Verifier.

	return 1;

} # End of check_organization_name.

# -----------------------------------------------

sub check_person_id
{
	my($self, $person_id) = @_; # Note: A max length of 10 is arbitrary.
	$person_id            = clean_user_data($person_id, 10, 1);
	my($expected_id)      = $self -> db -> session -> param('person_id') || 0;
	my($message)          = "Error: Person id is '$person_id' but in the session it's '$expected_id'\n";

	die $message if (! $expected_id);

	my($p_id) = $self -> db -> library -> validate_id('people', $person_id);

	die "Error: Person id is '$person_id' but this is not on file\n" if ($p_id == 0);
	die $message if ($person_id != $expected_id);

	# Return 1 for success as expected by Data::Verifier.

	return 1;

} # End of check_person_id.

# -----------------------------------------------

sub check_person_name
{
	my($self, $name) = @_;

	die "That person is already on file\n" if ($self -> db -> library -> validate_name('people', $name) > 0);

	# Return 1 for success as expected by Data::Verifier.

	return 1;

} # End of check_person_name.

# -----------------------------------------------

sub check_sid
{
	my($self, $sid)   = @_;
	my($expected_sid) = $self -> db -> session -> id;

	die "Error: Unexpected session id: '$sid'\n" if ($sid ne $expected_sid);

	return 1;

} # End of check_sid.

# -----------------------------------------------
# Warning: This is a function, not a method.

sub clean_user_data
{
	my($data, $max_length, $integer) = @_;
	$max_length ||= 250;
	$data       = '' if (! defined($data) || (length($data) == 0) || (length($data) > $max_length) );
	#$data      = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i); # http://www.perl.com/pub/a/2002/02/20/css.html.
	$data       = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);       # Ditto, but much more strict.
	$data       =~ s/^\s+//;
	$data       =~ s/\s+$//;
	$data       = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	return $data;

}	# End of clean_user_data.

# --------------------------------------------------

sub delete_note
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.delete_note()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			entity_id =>
			{
				post_check => sub {return $self -> check_entity_id(shift)},
				required   => 1,
				type       => 'Int',
			},
			entity_type =>
			{
				post_check => sub {return shift -> get_value('entity_type') =~ /^(?:organizations|people)/ ? 1 : 0},
				required   => 1,
				type       => 'Str',
			},
			note_id =>
			{
				required => 1,
				type     => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of delete_note.

# --------------------------------------------------

sub delete_occupation
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.delete_occupation()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			occupation_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('occupations', shift -> get_value('occupation_id') )},
				required   => 1,
				type       => 'Int',
			},
			# Can't validate organization's id because there may be no org displayed.
			# And in that case, there will be no organization's id in the session.
			#organization_id =>
			#{
			#	post_check => sub {return $self -> check_organization_id(shift -> get_value('organization_id') )},
			#	required   => 1,
			#	type       => 'Int',
			#},
			person_id =>
			{
				post_check => sub {return $self -> check_person_id(shift -> get_value('person_id') )},
				required   => 1,
				type       => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of delete_occupation.

# --------------------------------------------------

sub delete_staff
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.delete_staff()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			occupation_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('occupations', shift -> get_value('occupation_id') )},
				required   => 1,
				type       => 'Int',
			},
			organization_id =>
			{
				post_check => sub {return $self -> check_organization_id(shift -> get_value('organization_id') )},
				required   => 1,
				type       => 'Int',
			},
			# Can't validate person's id because there may be no person displayed.
			# And in that case, there will be no person's id in the session.
			#person_id =>
			#{
			#	post_check => sub {return $self -> check_person_id(shift -> get_value('person_id') )},
			#	required   => 1,
			#	type       => 'Int',
			#},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of delete_staff.

# --------------------------------------------------

sub find_organization
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.find_organization()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			organization_id =>
			{
				post_check => sub {return $self -> check_organization_id(shift -> get_value('organization_id') )},
				required   => 1,
				type       => 'Int',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of find_organization.

# --------------------------------------------------

sub find_person
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.find_person()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			person_id =>
			{
				post_check => sub {return $self -> check_person_id(shift -> get_value('person_id') )},
				required   => 1,
				type       => 'Int',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of find_person.

# --------------------------------------------------

sub log_result
{
	my($self, $result) = @_;

	$self -> app -> log(debug => 'Validation result: ' . ($result -> success ? 'Success' : 'Fail') );

	if (! $result -> success)
	{
		my($fields) = $result -> fields;

		for my $field_name ($result -> invalids)
		{
			$self -> app -> log(debug => "Error in $field_name: " . $$fields{$field_name} -> reason);
		}
	}

} # End of log_result.

# --------------------------------------------------

sub organization_profile
{
	my($self) = @_;

	return
	{
		communication_type_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('communication_types', shift -> get_value('communication_type_id') )},
			required   => 1,
			type       => 'Int',
		},
		email_address_1 =>
		{
			dependent =>
			{
				email_address_type_id_1 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_1') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		email_address_2 =>
		{
			dependent =>
			{
				email_address_type_id_2 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_2') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		email_address_3 =>
		{
			dependent =>
			{
				email_address_type_id_3 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_3') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		email_address_4 =>
		{
			dependent =>
			{
				email_address_type_id_4 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_4') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		facebook_tag =>
		{
			max_length => 250,
			required   => 0,
			type       => 'Str',
		},
		homepage =>
		{
			required => 0,
			type     => 'Str',
		},
		name =>
		{
			max_length => 250,
			required   => 1,
			type       => 'Str',
		},
		phone_number_1 =>
		{
			dependent =>
			{
				phone_number_type_id_1 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_1') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_2 =>
		{
			dependent =>
			{
				phone_number_type_id_2 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_2') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_3 =>
		{
			dependent =>
			{
				phone_number_type_id_3 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_3') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_4 =>
		{
			dependent =>
			{
				phone_number_type_id_4 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_4') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		role_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('roles', shift -> get_value('role_id') )},
			required   => 1,
			type       => 'Int',
		},
		sid =>
		{
			post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
			required   => 1,
			type       => 'Str',
		},
		twitter_tag =>
		{
			max_length => 250,
			required   => 0,
			type       => 'Str',
		},
		visibility_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('visibilities', shift -> get_value('visibility_id') )},
			required   => 1,
			type       => 'Int',
		},
	};

} # End of organization_profile.

# --------------------------------------------------

sub person_profile
{
	my($self) = @_;

	return
	{
		communication_type_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('communication_types', shift -> get_value('communication_type_id') )},
			required   => 1,
			type       => 'Int',
		},
		email_address_1 =>
		{
			dependent =>
			{
				email_address_type_id_1 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_1') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required  => 0,
			type      => 'Str',
		},
		email_address_2 =>
		{
			dependent =>
			{
				email_address_type_id_2 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_2') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		email_address_3 =>
		{
			dependent =>
			{
				email_address_type_id_3 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_3') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		email_address_4 =>
		{
			dependent =>
			{
				email_address_type_id_4 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('email_address_types', shift -> get_value('email_address_type_id_4') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		facebook_tag =>
		{
			max_length => 250,
			required   => 0,
			type       => 'Str',
		},
		gender_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('genders', shift -> get_value('gender_id') )},
			required   => 1,
			type       => 'Int',
		},
		given_names =>
		{
			max_length => 250,
			required   => 1,
			type       => 'Str',
		},
		homepage =>
		{
			required => 0,
			type     => 'Str',
		},
		phone_number_1 =>
		{
			dependent =>
			{
				phone_number_type_id_1 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_1') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_2 =>
		{
			dependent =>
			{
				phone_number_type_id_2 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_2') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_3 =>
		{
			dependent =>
			{
				phone_number_type_id_3 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_3') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		phone_number_4 =>
		{
			dependent =>
			{
				phone_number_type_id_4 =>
				{
					post_check => sub {return $self -> db -> library -> validate_id('phone_number_types', shift -> get_value('phone_number_type_id_4') )},
					required   => 1,
					type       => 'Int',
				}
			},
			required => 0,
			type     => 'Str',
		},
		preferred_name =>
		{
			max_length => 250,
			required   => 0,
			type       => 'Str',
		},
		role_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('roles', shift -> get_value('role_id') )},
			required   => 1,
			type       => 'Int',
		},
		sid =>
		{
			post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
			required   => 1,
			type       => 'Str',
		},
		surname =>
		{
			max_length => 250,
			required   => 1,
			type       => 'Str',
		},
		title_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('titles', shift -> get_value('title_id') )},
			required   => 1,
			type       => 'Int',
		},
		twitter_tag =>
		{
			max_length => 250,
			required   => 0,
			type       => 'Str',
		},
		visibility_id =>
		{
			post_check => sub {return $self -> db -> library -> validate_id('visibilities', shift -> get_value('visibility_id') )},
			required   => 1,
			type       => 'Int',
		},
	};

} # End of person_profile.

# --------------------------------------------------

sub report
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.report()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			communication_type_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('communication_types', shift -> get_value('communication_type_id') )},
				required   => 1,
				type       => 'Int',
			},
			gender_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('genders', shift -> get_value('gender_id') )},
				required   => 1,
				type       => 'Int',
			},
			ignore_communication_type =>
			{
				post_check => sub {return shift -> get_value('ignore_communication_type') =~ /^[01]$/ ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_gender =>
			{
				post_check => sub {return shift -> get_value('ignore_gender') =~ /^[01]$/ ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_role =>
			{
				post_check => sub {return shift -> get_value('ignore_role') =~ /^[01]$/ ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_visibility =>
			{
				post_check => sub {return shift -> get_value('ignore_visibility') =~ /^[01]$/ ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			report_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('reports', shift -> get_value('report_id') )},
				required   => 1,
				type       => 'Int',
			},
			report_entity_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('report_entities', shift -> get_value('report_entity_id') )},
				required   => 1,
				type       => 'Int',
			},
			role_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('roles', shift -> get_value('role_id') )},
				required   => 1,
				type       => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
			visibility_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('visibilities', shift -> get_value('visibility_id') )},
				required   => 1,
				type       => 'Int',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of report.

# --------------------------------------------------

sub update_note
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.update_note()');

	my($max_note_length) = ${$self -> config}{max_note_length};
	my($verifier)        = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			entity_id =>
			{
				post_check => sub {return $self -> check_entity_id(shift)},
				required   => 1,
				type       => 'Int',
			},
			entity_type =>
			{
				post_check => sub {return shift -> get_value('entity_type') =~ /^(?:organizations|people)/ ? 1 : 0},
				required   => 1,
				type       => 'Str',
			},
			body =>
			{
				# We can't call clean_user_data() as a filter here,
				# because we need to pass in the max length,
				# and we can't call it as a post_check, since it
				# returns the clean data, not an error flag.
				max_length => $max_note_length,
				min_length => 0, # Missing means
				required   => 0, # note is deleted.
				type       => 'Str',
			},
			note_id =>
			{
				required => 1,
				type     => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of update_note.

# --------------------------------------------------

sub update_organization
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.update_organization()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			%{$self -> organization_profile},
			organization_id =>
			{
				post_check => sub {return $self -> check_organization_id(shift -> get_value('organization_id') )},
				required   => 1,
				type       => 'Int',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of update_organization.

# --------------------------------------------------

sub update_person
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.update_person()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			%{$self -> person_profile},
			person_id =>
			{
				post_check => sub {return $self -> check_person_id(shift -> get_value('person_id') )},
				required   => 1,
				type       => 'Int',
			},
		},
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of update_person.

# --------------------------------------------------

sub validate_upload
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.validate_upload()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{	# TODO: This is a fake check, for the moment.
			sid =>
			{
				post_check => sub {return 1},
				required   => 0,
				type       => 'Str',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of validate_upload.

# --------------------------------------------------

sub validate_organization_id
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.validate_organization_id()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			organization_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('organizations', shift -> get_value('organization_id') )},
				required   => 1,
				type       => 'Int',
			},
			sid =>
			{
			post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
			required   => 1,
			type       => 'Str',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of validate_organization_id.

# --------------------------------------------------

sub validate_person_id
{
	my($self) = @_;

	$self -> app -> log(debug => 'Util::Validator.validate_person_id()');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			person_id =>
			{
				post_check => sub {return $self -> db -> library -> validate_id('people', shift -> get_value('person_id') )},
				required   => 1,
				type       => 'Int',
			},
			sid =>
			{
				post_check => sub {return $self -> check_sid(shift -> get_value('sid') )},
				required   => 1,
				type       => 'Str',
			},
		}
	);

	my($result) = $verifier -> verify({$self -> query -> Vars});

	$self -> log_result($result);

	return $result;

} # End of validate_person_id.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Validator - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is a L<Moo>-based object with these attributes:

=over 4

=item o app

Is a copy of the calling app object, and must be passed in to new().

E.g. It will be an instance of L<App::Office::Contacts::Controller::Exporter::Person>, etc.

=item o config

Is a hashref of config items, passed in to new().

=item o db

Is an instance of a L<App::Office::Contacts::Database>-based object, and must be passed in to new().

=item o query

Is a L<CGI>-style object, and must be passed in to new().

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 add_note()

Validates CGI form parameters when adding a Note.

=head2 add_occupation()

Validates CGI form parameters when adding an Occupation.

=head2 add_organization()

Validates CGI form parameters when adding an Organization.

=head2 add_person()

Validates CGI form parameters when adding a Person.

=head2 add_staff()

Validates CGI form parameters when adding a Staff member.

=head2 app()

Returns a copy of the calling app object passed in to new().

=head2 check_entity_id($result)

=head2 check_organization_id($organization_id)

=head2 check_organization_name($name)

=head2 check_person_id($person_id)

=head2 check_person_name($name)

=head2 check_sid($sid)

=head2 clean_user_data()

=head2 config()

Retturns a hashref of config items passed in to new().

=head2 db()

Returns an instance of a L<App::Office::Contacts::Database>-based object passed in to new().

=head2 delete_note()

Validates CGI form parameters when deleting a Note.

=head2 delete_occupation()

Validates CGI form parameters when deleting an Occupation.

=head2 delete_staff()

Validates CGI form parameters when deleting a Staff member.

=head2 find_organization()

=head2 find_person()

=head2 log_result($result)

=head2 organization_profile()

=head2 person_profile()

=head2 query()

Returns the L<CGI>-style object passed in to new().

=head2 report()

=head2 update_note()

Validates CGI form parameters when updating a Note.

=head2 update_organization()

Validates CGI form parameters when updating an Organization.

=head2 update_person()

Validates CGI form parameters when updating a Person.

=head2 validate_organization_id()

Validates just the organization_id and the sid (Session Id within L<Data::Session> within
L<App::Office::Contacts::Database>).

=head2 validate_person_id()

Validates just the person_id and the sid (See L<App::Office::Contacts::Controller::Exporter::Person>).

=head2 validate_upload()

Validates CGI form parameters when uploading a file (see L<App::Office::Contacts::Import::vCards>).

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
