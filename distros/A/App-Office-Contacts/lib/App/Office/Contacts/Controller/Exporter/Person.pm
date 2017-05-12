package App::Office::Contacts::Controller::Exporter::Person;

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
		get_occupations
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
		$self -> log(debug => 'Controller::Exporter::Person.add()');

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> add_person;

		if ($result -> success)
		{
			$response = $self -> param('db') -> library -> build_ok_xml
				(
					$self -> param('view') -> person -> add($self -> param('user_id'), $result)
				);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot add person',
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

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add delete get_occupations update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self)      = @_;
	my($person_id) = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Person.delete($person_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> find_person;

		if ($result -> success)
		{
			# Remove the person's id from the session.
			# JS will delete the 'update' tab displaying this person's data.

			$self -> param('db') -> session -> clear('person_id');
			$self -> param('db') -> person -> delete($person_id),

			$response = $self -> param('db') -> library -> build_ok_xml
				(
					$self -> query -> param('name')
				);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot delete person',
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

} # End of delete.

# -----------------------------------------------

sub display
{
	my($self)      = @_;
	my($person_id) = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Person.display($person_id)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> validate_person_id;

		if ($result -> success)
		{
			$self -> param('db') -> session -> param(person_id => $person_id);

	        my($persons)     = $self -> param('db') -> person -> get_person_list($self -> param('user_id'), $person_id);
			my($occupations) = $self -> param('db') -> person -> get_persons_occupations($person_id);
			my($notes)       = $self -> param('db') -> note -> get_notes('people', $person_id);
			$response        = $self -> param('view') -> person -> build_tab_html($$persons[0], $occupations, $notes);
			$response        = $self -> param('db') -> library -> build_ok_xml($response);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot display person',
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

	return encode('utf8', $response);

} # End of display.

# -----------------------------------------------

sub get_occupations
{
	my($self)      = @_;
	my($person_id) = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Person.get_occupations($person_id, ...)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> validate_person_id;

		if ($result -> success)
		{
			my($occupations) = $self -> param('db') -> person -> get_persons_occupations($person_id);
			$response        = $self -> param('view') -> occupation -> format_occupations($person_id, $occupations);
			$response        = $self -> param('db') -> library -> build_ok_xml($response);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot get list of occupations',
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

} # End of get_occupations.

# -----------------------------------------------

sub update
{
	my($self)      = @_;
	my($person_id) = $self -> query -> param('person_id');

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => "Controller::Exporter::Person.update($person_id, ...)");

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> update_person;

		if ($result -> success)
		{
			# This differs from the Organization code. See Controller::Export::Organization.update().

			$self -> param('view') -> person -> update($self -> param('user_id'), $result);

			$response = $self -> param('db') -> library -> build_ok_xml
				(
					$self -> query -> param('name')
				);
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot update person',
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

} # End of update.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller::Exporter::Person - A web-based contacts manager

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

item o (None)

=back

=head1 Methods

=head2 add()

This is a run mode for Person.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 cgiapp_init()

Provides L<CGI::Snapp> with the list of run modes.

=head2 delete()

This is a run mode for Person.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 display()

This is a run mode for Person.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 get_occupations()

This is a run mode for Person.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 update()

This is a run mode for Person.

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
