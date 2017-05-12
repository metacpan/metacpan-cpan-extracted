package App::Office::Contacts::Controller::Initialize;

use parent 'App::Office::Contacts::Controller';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Try::Tiny;

# We don't use Moo because we isa CGI::Snapp.

our $VERSION = '2.04';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'Controller::Initialize.display()');
	$self -> param('db') -> simple -> begin_work;

	my($response);

	try
	{
		$response = $self -> build_web_page;

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

	return $response;

} # End of display.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller::Initialize - A web-based contacts manager

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

Outputs the default web page in response to the default run mode.

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
