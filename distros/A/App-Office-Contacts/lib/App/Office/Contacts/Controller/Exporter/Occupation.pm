package App::Office::Contacts::Controller::Exporter::Occupation;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use App::Office::Contacts::Util::Validator;

use Encode; # For encode().

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		add_occupation
		add_staff
		build_ok_xml
		cgiapp_init
		delete_occupation
		delete_staff
	/],
};

use Text::Xslate 'mark_raw';

use Try::Tiny;

our $VERSION = '2.04';

# -----------------------------------------------

sub add_occupation
{
	my($self)      = @_;
	my($person_id) = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Occupation.add_occupation($person_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> add_occupation;

		if ($result -> success)
		{
			$self -> param('view') -> occupation -> add($self -> param('user_id'), $result);

			my($occupations) = $self -> param('db') -> person -> get_persons_occupations($person_id);
			$response        = $self -> param('view') -> occupation -> format_occupations($person_id, $occupations);
			$response        = $self -> build_ok_xml(mark_raw($response) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot add occupation',
				$result,
			);
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = $self -> param('system_error');
	};

	return encode('utf-8', $response);

} # End of add_occupation.

# -----------------------------------------------

sub add_staff
{
	my($self)            = @_;
	my($organization_id) = $self -> query -> param('organization_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Occupation.add_staff($organization_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> add_staff;

		if ($result -> success)
		{
			$self -> param('view') -> occupation -> add($self -> param('user_id'), $result);

			my($staff) = $self -> param('db') -> organization -> get_organizations_staff($organization_id);
			$response  = $self -> param('view') -> occupation -> format_staff($organization_id, $staff);
			$response  = $self -> build_ok_xml(mark_raw($response) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot add staff',
				$result,
			);
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = $self -> param('system_error');
	};

	return encode('utf-8', $response);

} # End of add_staff.

# -----------------------------------------------

sub build_ok_xml
{
	my($self, $html) = @_;

	$self -> log(debug => 'Controller::Occupation.build_ok_xml(...)');

	# Recover the organization id and person id from the session.
	# See delete_occupation()
	# and App::Office::Contacts::View::Occupation.add()

	my($organization_id) = $self -> param('db') -> session -> param('staff_organization_id');
	my($person_id)       = $self -> param('db') -> session -> param('occupation_person_id');

	return
qq|<response>
	<error></error>
	<org_id>$organization_id</org_id>
	<person_id>$person_id</person_id>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_ok_xml.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add_occupation add_staff delete_occupation delete_staff/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete_occupation
{
	my($self)            = @_;
	my($occupation_id)   = $self -> query -> param('occupation_id');
	my($organization_id) = $self -> query -> param('organization_id');
	my($person_id)       = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Occupation.delete_occupation($occupation_id, $organization_id, $person_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> delete_occupation;

		if ($result -> success)
		{
			$self -> param('db') -> occupation -> delete($occupation_id);

			# The next 2 are required for build_xml().

			$self -> param('db') -> session -> param(staff_organization_id => $organization_id);
			$self -> param('db') -> session -> param(occupation_person_id  => $person_id);

			my($occupations) = $self -> param('db') -> person -> get_persons_occupations($person_id);
			$response        = $self -> param('view') -> occupation -> format_occupations($person_id, $occupations);
			$response        = $self -> build_ok_xml(mark_raw($response) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot delete occupation',
				$result,
			);
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = $self -> param('system_error');
	};

	return encode('utf-8', $response);

} # End of delete_occupation.

# -----------------------------------------------

sub delete_staff
{
	my($self)            = @_;
	my($occupation_id)   = $self -> query -> param('occupation_id');
	my($organization_id) = $self -> query -> param('organization_id');
	my($person_id)       = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Occupation.delete_staff($occupation_id, $organization_id, $person_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> delete_staff;

		if ($result -> success)
		{
			$self -> param('db') -> occupation -> delete($occupation_id);

			# The next 2 are required for build_xml().

			$self -> param('db') -> session -> param(staff_organization_id => $organization_id);
			$self -> param('db') -> session -> param(occupation_person_id  => $person_id);

			my($staff) = $self -> param('db') -> organization -> get_organizations_staff($organization_id);
			$response  = $self -> param('view') -> occupation -> format_staff($organization_id, $staff);
			$response  = $self -> build_ok_xml(mark_raw($response) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot delete staff',
				$result,
			);
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = $self -> param('system_error');
	};

	return encode('utf-8', $response);

} # End of delete_staff.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller::Exporter::Occupation - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is an L<App::Office::Contacts::Controller>-based object with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 add_occupation()

This is a run mode for Occupation.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 add_staff()

This is a run mode for Occupation.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 build_xml($type, $html)

Builds XML for an Ajax response.

=head2 cgiapp_init()

Provides L<CGI::Snapp> with the list of run modes.

=head2 delete_occupation()

This is a run mode for Occupation.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 delete_staff()

This is a run mode for Occupation.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

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
