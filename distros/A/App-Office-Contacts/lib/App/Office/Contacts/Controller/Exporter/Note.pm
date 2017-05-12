package App::Office::Contacts::Controller::Exporter::Note;

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
		get_notes
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
		$self -> log(debug => 'Controller::Exporter::Note.add()');

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> add_note;

		if ($result -> success)
		{
			$self -> param('view') -> note -> add($self -> param('user_id'), $result);

			$response = $self -> param('db') -> library -> build_ok_xml($self -> get_notes($result) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot add note',
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

	$self -> run_modes([qw/add delete update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self) = @_;

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => 'Controller::Exporter::Note.delete()');

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> delete_note;

		if ($result -> success)
		{
			$self -> param('view') -> note -> delete($self -> param('user_id'), $result);

			$response = $self -> param('db') -> library -> build_ok_xml($self -> get_notes($result) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot delete note',
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

sub get_notes
{
	my($self, $result) = @_;

	$self -> param('db') -> logger -> log(debug => 'Controller::Exporter::Note.get_notes(...)');

	my($entity_id)     = $result -> get_value('entity_id');
	my($entity_type)   = $result -> get_value('entity_type');
	my($notes)         = $self -> param('db') -> note -> get_notes($entity_type, $entity_id);

	if ($entity_type eq 'people')
	{
		$result = $#$notes >= 0 ? $self -> param('view') -> note -> format_person_notes($entity_id, $notes) : '';
	}
	else
	{
		$result = $#$notes >= 0 ? $self -> param('view') -> note -> format_organization_notes($entity_id, $notes) : '';
	}

	return $result;

} # End of get_notes.

# -----------------------------------------------

sub update
{
	my($self) = @_;

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response, $result);

	try
	{
		$self -> log(debug => 'Controller::Exporter::Note.update()');

		$result = App::Office::Contacts::Util::Validator -> new
		(
			app    => $self,
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> update_note;

		if ($result -> success)
		{
			my($text) = $result -> get_value('body') || ''; # Content may have been deleted.

			if (length($text) == 0)
			{
				$self -> param('view') -> note -> delete($self -> param('user_id'), $result);
			}
			else
			{
				$self -> param('view') -> note -> update($self -> param('user_id'), $result);
			}

			$response = $self -> param('db') -> library -> build_ok_xml($self -> get_notes($result) );
		}
		else
		{
			$response = $self -> param('db') -> library -> build_error_xml
			(
				'Cannot update note',
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

App::Office::Contacts::Controller::Exporter::Note - A web-based contacts manager

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

This is a run mode for Note.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 cgiapp_init()

Provides L<CGI::Snapp> with the list of run modes.

=head2 delete()

This is a run mode for Note.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 get_notes($result)

This is a run mode for Note.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 update()

This is a run mode for Note.

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
