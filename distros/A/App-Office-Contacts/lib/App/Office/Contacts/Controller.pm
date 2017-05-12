package App::Office::Contacts::Controller;

use parent 'App::Office::Contacts';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use App::Office::Contacts::Database;
use App::Office::Contacts::Util::Logger;
use App::Office::Contacts::View;

# We don't use Moo because we isa CGI::Snapp.

our $VERSION = '2.04';

# -----------------------------------------------

sub cgiapp_prerun
{
	my($self, $rm) = @_;

	# Can't call log() yet, since logger not set up.
	#$self -> log(debug => 'Controller.cgiapp_prerun');

	$self -> logger(App::Office::Contacts::Util::Logger -> new);
	$self -> log(debug => '');
	$self -> log(debug => 'Controller.cgiapp_prerun');
	$self -> param(config => $self -> logger -> module_config);

	# Set up the database. The reason for these parameters
	# is that the db is also used by Import.

	$self -> param
	(
		db => App::Office::Contacts::Database -> new
		(
			logger        => $self -> logger,
			module_config => $self -> logger -> module_config,
			query         => $self -> query,
		)
	);

	# Set up the things shared by:
	# o App::Office::Contacts
	# o App::Office::Contacts::Donations
	# o App::Office::Contacts::Import::vCards

	$self -> global_prerun;

	# Set up the view.

	$self -> param(view => App::Office::Contacts::View -> new
	(
		db => $self -> param('db'),
	) );

} # End of cgiapp_prerun.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Controller - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

=over 4

=item o See the parent module L<App::Office::Contacts>

=back

=head1 Methods

=head2 cgiapp_prerun($rm)

This is called automatically by L<CGI::Snapp> at the start of each run mode.

If calls L<App::Office::Contacts/global_prerun()>.

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
