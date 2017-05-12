package App::Office::Contacts::Controller::Exporter::Organization;

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
		add
		cgiapp_init
		delete
		display
		get_staff
		update
	/],
};

use Try::Tiny;

our $VERSION = '2.04';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => 'Controller::Exporter::Org.add()');

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> add_organization;

		if ($result -> success)
		{
			$response = $self -> param('db') -> library -> build_ok_xml
				(
					$self -> param('view') -> organization -> add($self -> param('user_id'), $result)
				);
		}
		else
		{
			$response = 'Error: Validation failed';
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = 'Error: Software error';
	};

	$self -> log(debug => 'Run mode response: ' . ($response =~ /^Error/ ? $response : 'OK') );

	return encode('utf-8', $response);

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add delete get_staff update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self)            = @_;
	my($organization_id) = $self -> query -> param('organization_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Org.delete($organization_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> find_organization;

		if ($result -> success)
		{
			# Remove the organization's id from the session.
			# JS will delete the 'update' tab displaying this organization's data.

			$self -> param('db') -> session -> clear('organization_id');
			$self -> param('db') -> organization -> delete($organization_id);

			$response = $self -> param('db') -> library -> build_ok_xml
				(
					$self -> query -> param('name')
				);
		}
		else
		{
			$response = 'Error: Validation failed';
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = 'Error: Software error';
	};

	$self -> log(debug => 'Run mode response: ' . ($response =~ /^Error/ ? $response : 'OK') );

	return encode('utf-8', $response);

} # End of delete.

# -----------------------------------------------

sub display
{
	my($self)            = @_;
	my($organization_id) = $self -> query -> param('organization_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Org.display($organization_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> validate_organization_id;

		if ($result -> success)
		{
			$self -> param('db') -> session -> param(organization_id => $organization_id);

	        my($orgs)  = $self -> param('db') -> organization -> get_organization_list($self -> param('user_id'), $organization_id);
			my($staff) = $self -> param('db') -> organization -> get_organizations_staff($organization_id);
			my($notes) = $self -> param('db') -> note -> get_notes('organizations', $organization_id);
			$response  = $self -> param('view') -> organization -> build_tab_html($$orgs[0], $staff, $notes);
			$response  = $self -> param('db') -> library -> build_ok_xml($response);
		}
		else
		{
			$response = 'Error: Validation failed';
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = 'Error: Software error';
	};

	$self -> log(debug => 'Run mode response: ' . ($response =~ /^Error/ ? $response : 'OK') );

	return encode('utf-8', $response);

} # End of display.

# -----------------------------------------------

sub get_staff
{
	my($self)            = @_;
	my($organization_id) = $self -> query -> param('organization_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Org.get_staff($organization_id, ...)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> validate_organization_id;

		if ($result -> success)
		{
			my($staff) = $self -> param('db') -> organization -> get_organizations_staff($organization_id);
			$response  = $self -> param('view') -> occupation -> format_staff($organization_id, $staff);
			$response  = $self -> param('db') -> library -> build_ok_xml($response);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot get list of staff',
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

} # End of get_staff.

# -----------------------------------------------

sub update
{
	my($self)            = @_;
	my($organization_id) = $self -> query -> param('organization_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Org.update($organization_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> update_organization;

		if ($result -> success)
		{
			# This differs from the Person code because the user might
			# try to delete or update the special organization '-'.

			$response = $self -> param('view') -> organization -> update($self -> param('user_id'), $result);
			$response = $self -> param('db') -> library -> build_ok_xml($response);
		}
		else
		{
			$response = 'Error: Validation failed';
		}

		$self -> param('db') -> simple -> commit;
	}
	catch
	{
		my($error) = $_;

		$self -> param('db') -> simple -> rollback;

		# Try to log the error despite the error.

		$self -> log(error => "System error: $error");

		$response = 'Error: Software error';
	};

	$self -> log(debug => 'Run mode response: ' . ($response =~ /^Error/ ? $response : 'OK') );

	return encode('utf-8', $response);

} # End of update.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller::Exporter::Organization - A web-based contacts manager

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

=head2 add()

This is a run mode for Organization.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 cgiapp_init()

Provides L<CGI::Snapp> with the list of run modes.

=head2 delete()

This is a run mode for Organization.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 display()

This is a run mode for Organization.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 get_staff()

This is a run mode for Organization.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 update()

This is a run mode for Organization.

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
