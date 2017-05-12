package App::Office::Contacts::Util::Import;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use App::Office::Contacts::Database;
use App::Office::Contacts::Util::Logger;

use CGI;

use DBIx::Admin::CreateTable;

use Encode; # For decode() and encode().

use FindBin;

use Moo;

use Text::CSV::Encoded;

use Time::Stamp -stamps => {dt_sep => ' ', us => 1};

extends 'App::Office::Contacts::Database::Base';

has logger =>
(
	default  => sub{return 0},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Util::Logger',
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	#isa     => 'Int',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;

	$self -> logger(App::Office::Contacts::Util::Logger -> new);
	$self -> db
	(
		App::Office::Contacts::Database -> new
		(
			logger        => $self -> logger,
			module_config => $self -> logger -> module_config,
			query         => CGI -> new,
		)
	);

}	# End of BUILD.

# -----------------------------------------------

sub dump
{
	my($self, $table_name) = @_;

	if (! $self -> verbose)
	{
		return;
	}

	my(@record) = $self -> db -> simple -> query("select * from $table_name order by id") -> hashes;

	print "\t$table_name: \n";

	my($row);

	for $row (@record)
	{
		print "\t";
		print map{"$_ => " . decode('utf-8', $$row{$_}) . ". "} sort keys %$row;
		print "\n";
	}

	print "\n";

} # End of dump.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	# Warning: The order of these calls is important.

	$self -> populate_visibilities_table;
	$self -> populate_communication_types_table;
	$self -> populate_genders_table;
	$self -> populate_report_entities_table;
	$self -> populate_reports_table;
	$self -> populate_roles_table;
	$self -> populate_titles_table;
	$self -> populate_yes_noes_table;
	$self -> populate_email_address_types_table;
	$self -> populate_phone_number_types_table;
	$self -> populate_occupation_titles_table;
	$self -> populate_organizations_table;

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_communication_types_table
{
	my($self)       = @_;
	my($table_name) = 'communication_types';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_communication_types_table.

# -----------------------------------------------

sub populate_email_address_types_table
{
	my($self)       = @_;
	my($table_name) = 'email_address_types';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_address_types_table.

# -----------------------------------------------

sub populate_email_addresses_table
{
	my($self)       = @_;
	my($table_name) = 'email_addresses';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	my(@field, %field);

	# Each element of @$data is a hashref: {email_address_type_id => $value, address => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_addresses_table.

# -----------------------------------------------

sub populate_email_organizations_table
{
	my($self)       = @_;
	my($table_name) = 'email_organizations';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref: {email_address_id => $value, organizations_id => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_organizations_table.

# -----------------------------------------------

sub populate_email_people_table
{
	my($self)       = @_;
	my($table_name) = 'email_people';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref: {email_address_id => $value, person_id => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_email_people_table.

# -----------------------------------------------

sub populate_fake_data
{
	my($self) = @_;

	$self -> populate_fake_people_table;
	$self -> populate_email_addresses_table;
	$self -> populate_phone_numbers_table;
	$self -> populate_fake_occupation_titles_table;
	$self -> populate_fake_organizations_table;
	$self -> populate_email_people_table;
	$self -> populate_phone_people_table;
	$self -> populate_email_organizations_table;
	$self -> populate_phone_organizations_table;

	return 0;

} # End of populate_fake_data.

# -----------------------------------------------

sub populate_fake_occupation_titles_table
{
	my($self)       = @_;
	my($table_name) = 'occupation_titles';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref: {name => $value, upper_name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_fake_occupation_titles_table.

# -----------------------------------------------

sub populate_fake_organizations_table
{
	my($self)       = @_;
	my($table_name) = 'organizations';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# visibility_id, communication_type_id, creator_id, role_id, homepage, name.
	# Sub read_a_file() decoded the data, so we can use uc() but then have to call encode().

	for (@$data)
	{
		$$_{upper_name} = encode('utf-8', uc $$_{name});
		$$_{timestamp}  = localstamp;

		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_fake_organizations_table.

# -----------------------------------------------

sub populate_fake_people_table
{
	my($self)       = @_;
	my($table_name) = 'people';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# visibility_id, communication_type_id, creator_id, deleted, facebook_tag, gender_id, role_id, title_id, twitter_tag, date_of_birth, given_names, homepage, name, preferred_name, surname.
	# Sub read_a_file() decoded the data, so we can use uc() but then have to call encode().

	for (@$data)
	{
		# Setting upper_given_names is for the search code.
		# See App::Office::Contacts::Controller::Exporter::Search.

		$$_{upper_given_names} = encode('utf-8', uc $$_{given_names});
		$$_{upper_name}        = encode('utf-8', uc $$_{name});
		$$_{timestamp}         = localstamp;

		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_fake_people_table.

# -----------------------------------------------

sub populate_genders_table
{
	my($self)       = @_;
	my($table_name) = 'genders';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_genders_table.

# -----------------------------------------------

sub populate_occupation_titles_table
{
	my($self)       = @_;
	my($table_name) = 'occupation_titles';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value, upper_name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_occupation_titles_table.

# -----------------------------------------------

sub populate_organizations_table
{
	my($self)       = @_;
	my($table_name) = 'organizations';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# visibility_id, communication_type_id, creator_id, deleted, facebook_tag, twitter_tag, role_id, homepage, name.
	# Sub read_a_file() decoded the data, so we can use uc() but then have to call encode().

	for (@$data)
	{
		$$_{upper_name} = encode('utf-8', uc $$_{name});
		$$_{timestamp}  = localstamp;

		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_organizations_table.

# -----------------------------------------------

sub populate_phone_number_types_table
{
	my($self)       = @_;
	my($table_name) = 'phone_number_types';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_number_types_table.

# -----------------------------------------------

sub populate_phone_numbers_table
{
	my($self)       = @_;
	my($table_name) = 'phone_numbers';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# phone_number_type_id number

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_numbers_table.

# -----------------------------------------------

sub populate_phone_organizations_table
{
	my($self)       = @_;
	my($table_name) = 'phone_organizations';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# organization_id, phone_number_id

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_organizations_table.

# -----------------------------------------------

sub populate_phone_people_table
{
	my($self)       = @_;
	my($table_name) = 'phone_people';
	my($data)       = $self -> read_a_file("fake.$table_name.txt");

	# Each element of @$data is a hashref with these keys:
	# person_id, phone_number_id

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_phone_people_table.

# -----------------------------------------------

sub populate_report_entities_table
{
	my($self)       = @_;
	my($table_name) = 'report_entities';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_report_entities_table.

# -----------------------------------------------

sub populate_reports_table
{
	my($self)       = @_;
	my($table_name) = 'reports';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_reports_table.

# -----------------------------------------------

sub populate_roles_table
{
	my($self)       = @_;
	my($table_name) = 'roles';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_roles_table.

# -----------------------------------------------

sub populate_titles_table
{
	my($self)       = @_;
	my($table_name) = 'titles';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_titles_table.

# -----------------------------------------------

sub populate_visibilities_table
{
	my($self)       = @_;
	my($table_name) = 'visibilities';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_visibilities_table.

# -----------------------------------------------

sub populate_yes_noes_table
{
	my($self)       = @_;
	my($table_name) = 'yes_noes';
	my($data)       = $self -> read_a_file("$table_name.txt");

	# Each element of @$data is a hashref: {name => $value}.

	for (@$data)
	{
		$self -> db -> simple -> insert($table_name, $_);
	}

	$self -> logger -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_yes_noes_table.

# -----------------------------------------------

sub read_a_file
{
	my($self, $input_file_name) = @_;
	$input_file_name = "$FindBin::Bin/../data/$input_file_name";
	my($csv)         = Text::CSV::Encoded -> new({allow_whitespace => 1, encoding_in => 'utf8'});

	open my $io, '<', $input_file_name;
	$csv -> column_names($csv -> getline($io) );
	my($data) = $csv -> getline_hr_all($io);
	close $io;

	return $data;

} # End of read_a_file.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Import - A web-based contacts manager

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

=item o logger

Is an instance of an L<App::Office::Contacts::Util::Logger> object.

=item o verbose

Is a Boolean.

Default: 0.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 dump($table_name)

=head2 logger()

Returns an instance of an L<App::Office::Contacts::Util::Logger> object.

=head2 populate_all_tables()

Calls all the non-fake populate_*_table methods, in a special order so that foreign key relationships just work.

=head2 populate_communication_types_table()

=head2 populate_email_address_types_table()

=head2 populate_email_addresses_table()

=head2 populate_email_organizations_table()

=head2 populate_email_people_table()

=head2 populate_fake_data()

Calls all the fake populate_*_table methods, in a special order so that foreign key relationships just work.

=head2 populate_fake_occupation_titles_table()

=head2 populate_fake_organizations_table()

=head2 populate_fake_people_table()

=head2 populate_genders_table()

=head2 populate_occupation_titles_table()

=head2 populate_organizations_table()

=head2 populate_phone_number_types_table()

=head2 populate_phone_numbers_table()

=head2 populate_phone_organizations_table()

=head2 populate_phone_people_table()

=head2 populate_report_entities_table()

=head2 populate_reports_table()

=head2 populate_roles_table()

=head2 populate_titles_table()

=head2 populate_visibilities_table()

=head2 populate_yes_noes_table()

=head2 read_a_file($input_file_name)

=head2 verbose()

Returns a Boolean.

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
