package App::Office::Contacts::Controller::Exporter::Search;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Encode; # For decode(), encode().

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		display
		remove_duplicates
	/],
};

use Try::Tiny;

our $VERSION = '2.04';

# -----------------------------------------------

sub display
{
	my($self)   = @_;
	my($key)    = $self -> query -> param('search_name') || '';
	my($uc_key) = encode('utf-8', uc decode('utf-8', $key) );

	$self -> param('db') -> simple -> begin_work;
	$self -> add_header('-Status' => 200, '-Content-Type' => 'text/xml; charset=utf-8');

	my($response);

	try
	{
		$self -> log(debug => "Controller::Exporter::Search.display($uc_key)");

		# Here we get:
		# o Organizations whose names match.
		# o People whose names match.
		# o Organizations whose email addresses match.
		# o People whose email addresses match.
		# o Organizations whose phone numbers match.
		# o People whose phone numbers match.
		# Then we winnow those sets, i.e we remove duplicates.

		my($user_id)       = $self -> param('user_id');
		my($organizations) = $self -> param('db') -> organization -> get_organizations($user_id, $uc_key);
		my($people)        = $self -> param('db') -> person -> get_people($user_id, $uc_key);
		my(@emails)        = $self -> param('db') -> email_address -> get_organizations_and_people($user_id, $uc_key);
		my(@phones)        = $self -> param('db') -> phone_number -> get_organizations_and_people($user_id, $uc_key);
		$organizations     = $self -> remove_duplicates($organizations, $emails[1], $phones[1]);
		$people            = $self -> remove_duplicates($people, $emails[0], $phones[0]);
		my($row)           =
		[
			# We put people before organizations. Do not use 'sort' here because
			# of the way we've formatted multiple entries for each person/organization.

			@{$self -> param('view') -> person -> format_search_result($uc_key, $people)},
			@{$self -> param('view') -> organization -> format_search_result($uc_key, $organizations)},
		];

		$response = $self -> param('db') -> library -> build_ok_xml
			(
				$self -> param('view') -> search -> display($uc_key, $row)
			);

		$self -> param('db') -> simple -> commit;
		$self -> log(debug => "Final search count: @{[scalar @$row]}");
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

} # End of display.

# -----------------------------------------------

sub remove_duplicates
{
	my($self, @arrayrefs) = @_;

	my(%seen);
	my(@unique);

	for my $arrayref (@arrayrefs)
	{
		for my $item (@$arrayref)
		{
			next if ($seen{$$item{id} });

			push @unique, $item;

			$seen{$$item{id} } = 1;
		}
	}

	return [@unique];

} # End of remove_duplicates.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller::Exporter::Search - A web-based contacts manager

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

=head2 display()

This is the run mode for Search.

It finds matching records, removes duplicates, and formats the results.

See htdocs/assets/templates/app/office/contacts/homepage.tx for the calling code.

=head2 remove_duplicates(@arrayrefs)

This method is called by display().

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
