package App::Office::Contacts::Database::AutoComplete;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For decode().

use Moo;

extends 'App::Office::Contacts::Database::Base';

our $VERSION = '2.04';

# --------------------------------------------------

sub occupation_title
{
	my($self, $name) = @_;
	$name = uc decode('utf-8', $name);

	$self -> db -> logger -> log(debug => "Database::AutoComplete.occupation_title($name)");

	my($result) = $self -> db -> simple -> query('select name from occupation_titles where upper_name like ? order by upper_name', "%$name%")
					|| die $self -> db -> simple -> error;

	# flat() implies there may be N matching records.

	return $self -> db -> library -> decode_list($result -> flat);

} # End of occupation_title.

# --------------------------------------------------

sub organization_name
{
	my($self, $name) = @_;
	$name = uc decode('utf-8', $name);

	$self -> db -> logger -> log(debug => "Database::AutoComplete.organization_name($name)");

	my($result) = $self -> db -> simple -> query('select name from organizations where upper_name like ? order by upper_name', "%$name%")
					|| die $self -> db -> simple -> error;

	# flat() implies there may be N matching records.

	return $self -> db -> library -> decode_list($result -> flat);

} # End of organization_name.

# --------------------------------------------------

sub person_name
{
	my($self, $name) = @_;
	$name = uc decode('utf-8', $name);

	$self -> db -> logger -> log(debug => "Database::AutoComplete.person_name($name)");

	my($result) = $self -> db -> simple -> query('select name from people where upper(name) like ? order by name', "%$name%")
		|| die $self -> db -> simple -> error;

	# flat() implies there may be N matching records.

	return $self -> db -> library -> decode_list($result -> flat);

} # End of person_name.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::AutoComplete - A web-based contacts manager

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

=item o (None)

=back

=head1 Methods

=head2 occupation_title($name)

Returns a list of occupation titles which match $name.

=head2 organization_name($name)

Returns a list of organizations which match $name.

=head2 person_name($name)

Returns a list of people whose names match $name.

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
