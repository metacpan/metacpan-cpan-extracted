package App::Office::Contacts::Database;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Session;

use App::Office::Contacts::Database::AutoComplete;
use App::Office::Contacts::Database::EmailAddress;
use App::Office::Contacts::Database::Library;
use App::Office::Contacts::Database::Note;
use App::Office::Contacts::Database::Occupation;
use App::Office::Contacts::Database::Organization;
use App::Office::Contacts::Database::Person;
use App::Office::Contacts::Database::PhoneNumber;

use Moo;

use Text::Xslate;

has autocomplete =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::AutoComplete',
	required => 0,
);

has email_address =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::EmailAddress',
	required => 0,
);

has library =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::Library',
	required => 0,
);

has logger =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Util::Logger',
	required => 1,
);

has module_config =>
(
	default  => sub{return {} },
	is       => 'rw',
	#isa     => 'HashRef',
	required => 1,
);

has note =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::Note',
	required => 0,
);

has occupation =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::Occupation',
	required => 0,
);

has organization =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::Organization',
	required => 0,
);

has person =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::Person',
	required => 0,
);

has phone_number =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database::PhoneNumber',
	required => 0,
);

has query =>
(
	default  => sub{return ''},
	is       => 'ro',
	#isa     => 'Any',
	required => 1,
);

has session =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Data::Session',
	required => 0,
);

has simple =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'DBIx::Simple',
	required => 0,
);

has templater =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Text::Xslate',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> module_config;

	# We do this to short-circuit $self -> logger -> simple everywhere.

	$self -> simple($self -> logger -> simple);
	$self -> templater
	(
		Text::Xslate -> new
		(
			input_layer => '',
			path        => $$config{template_path},
		)
	);

	# Set up the session. To simplify things we always use
	# Data::Session, and ignore the PSGI alternative.

	$self -> session
	(
		Data::Session -> new
		(
			data_source => $$config{dsn},
			dbh         => $self -> simple -> dbh,
			name        => 'sid',
			pg_bytea    => $$config{pg_bytea} || 0,
			pg_text     => $$config{pg_text}  || 0,
			query       => $self -> query,
			table_name  => $$config{session_table_name},
			type        => $$config{session_driver},
		)
	);

	# Force the session object to be updated by setting an arbitrary parameter.
	# This means the object will be flushed in the teardown phase.

	$self -> session -> param(_initialized => 1);

	$self -> autocomplete(App::Office::Contacts::Database::AutoComplete -> new
	(
		db => $self,
	) );

	$self -> email_address(App::Office::Contacts::Database::EmailAddress -> new
	(
		db => $self,
	) );

	$self -> note(App::Office::Contacts::Database::Note -> new
	(
		db => $self,
	) );

	$self -> occupation(App::Office::Contacts::Database::Occupation -> new
	(
		db => $self,
	) );

	$self -> organization(App::Office::Contacts::Database::Organization -> new
	(
		db => $self,
	) );

	$self -> person(App::Office::Contacts::Database::Person -> new
	(
		db => $self,
	) );

	$self -> phone_number(App::Office::Contacts::Database::PhoneNumber -> new
	(
		db => $self,
	) );

	# The next call sets $self -> library().
	# It allows init() to be overridden by a subclass,
	# specifically App::Office::Contacts::Donations::Database.

	$self -> init;

}	# End of BUILD.

# --------------------------------------------------

sub init
{
	my($self) = @_;

	$self -> library(App::Office::Contacts::Database::Library -> new
	(
		db => $self,
	) );

} # End of init.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database - A web-based contacts manager

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

=item o autocomplete

Is an object of type L<App::Office::Contacts::Database::AutoComplete>.

=item o email_address

Is an object of type L<App::Office::Contacts::Database::EmailAddress>.

=item o library

Is an object of type L<App::Office::Contacts::Database::Library>.

=item o logger

Is an object of type L<App::Office::Contacts::Util::Logger>, and must be passed in to new().

=item o module_config

Is a hashref of options read from share/.htapp.office.contacts.conf, and must be passed in to new().

=item o note

Is an object of type L<App::Office::Contacts::Database::Note>.

=item o occupation

Is an object of type L<App::Office::Contacts::Database::Occupation>.

=item o organization

Is an object of type L<App::Office::Contacts::Database::Organization>.

=item o person

Is an object of type L<App::Office::Contacts::Database::Person>.

=item o phone_number

Is an object of type L<App::Office::Contacts::Database::PhoneNumber>.

=item o query

Is a L<CGI>-style object, and must be passed in to new().

=item o session

Is an object of type L<Data::Session>.

=item o simple

Is an object of type L<DBIx::Simple>, copied from the L<App::Office::Contacts::Util::Logger> object.
This is done to shorted the method call chain.

=item o templater

Is an object of type L<Text::Xslate>.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 autocomplete()

Returns an object of type L<App::Office::Contacts::Database::AutoComplete>.

=head2 email_address()

Returns an object of type L<App::Office::Contacts::Database::EmailAddress>.

=head2 init()

This method is called from BUILD(), and is designed to be overridden by sub-classes.

=head2 library

Returns an object of type L<App::Office::Contacts::Database::Library>.

=head2 logger()

Returns an object of type L<App::Office::Contacts::Util::Logger>.

=head2 module_config()

Returns a hashref of options read from share/.htapp.office.contacts.conf and passed in to new().

=head2 note()

Returns an object of type L<App::Office::Contacts::Database::Note>.

=head2 occupation()

Returns an object of type L<App::Office::Contacts::Database::Occupation>.

=head2 organization()

Returns an object of type L<App::Office::Contacts::Database::Organization>.

=head2 person()

Returns an object of type L<App::Office::Contacts::Database::Person>.

=head2 phone_number()

Returns an object of type L<App::Office::Contacts::Database::PhoneNumber>.

=head2 query()

Returns the L<CGI>-style object passed in to new().

=head2 session()

Returns an object of type L<Data::Session>.

=head2 simple()

Returns an object of type L<DBIx::Simple>.

=head2 templater()

Returns an object of type L<Text::Xslate>.

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
