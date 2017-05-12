package App::Office::Contacts::View;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use App::Office::Contacts::View::Note;
use App::Office::Contacts::View::Occupation;
use App::Office::Contacts::View::Organization;
use App::Office::Contacts::View::Person;
use App::Office::Contacts::View::Report;
use App::Office::Contacts::View::Search;

use Moo;

extends 'App::Office::Contacts::View::Base';

has note =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::View::Note',
	required => 0,
);

has occupation =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::View::Occupation',
	required => 0,);

has organization =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::View::Organization',
	required => 0,);

has person =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::View::Person',
	required => 0,);

has report =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Any',
	required => 0,);

has search =>
(
	is       => 'rw',
	#isa     => 'App::Office::Contacts::View::Search',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# init() is called in this way so that both this module and
	# App::Office::Contacts::Donations::View will use the
	# appropriate config and db parameters to initialize their
	# attributes.

	$self -> init;

}	# End of BUILD.

# --------------------------------------------------

sub init
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'Entered init');

	$self -> note(App::Office::Contacts::View::Note -> new
	(
		db   => $self -> db,
		view => $self,
	) );

	$self -> occupation(App::Office::Contacts::View::Occupation -> new
	(
		db   => $self -> db,
		view => $self,
	) );

	$self -> organization(App::Office::Contacts::View::Organization -> new
	(
		db   => $self -> db,
		view => $self,
	) );

	$self -> person(App::Office::Contacts::View::Person -> new
	(
		db   => $self -> db,
		view => $self,
	) );

	$self -> report(App::Office::Contacts::View::Report -> new
	(
		db   => $self -> db,
		view => $self,
	) );

	$self -> search(App::Office::Contacts::View::Search -> new
	(
		db   => $self -> db,
		view => $self,
	) );

} # End of init.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View - A web-based contacts manager

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

=item o note

Is an object of type L<App::Office::Contacts::View::Note>.

=item o occupation

Is an object of type L<App::Office::Contacts::View::Occupation>.

=item o organization

Is an object of type L<App::Office::Contacts::View::Organization>.

=item o person

Is an object of type L<App::Office::Contacts::View::Person>.

=item o report

Is an object of type L<App::Office::Contacts::View::Report>.

=item o search

Is an object of type L<App::Office::Contacts::View::Search>.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 init()

This method is called from BUILD(), and is designed to be overridden by sub-classes.

=head2 note()

Returns an object of type L<App::Office::Contacts::View::Note>.

=head2 occupation()

Returns an object of type L<App::Office::Contacts::View::Occupation>.

=head2 organization()

Returns an object of type L<App::Office::Contacts::View::Organization>.

=head2 person()

Returns an object of type L<App::Office::Contacts::View::Person>.

=head2 report()

Returns an object of type L<App::Office::Contacts::View::Report>.

=head2 search()

Returns an object of type L<App::Office::Contacts::View::Search>.

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
