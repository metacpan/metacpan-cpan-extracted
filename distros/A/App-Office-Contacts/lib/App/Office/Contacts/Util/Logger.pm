package App::Office::Contacts::Util::Logger;

use strict;
use utf8;
use warnings;

use DBIx::Simple;

use Log::Handler::Output::DBI;

use Moo;

extends 'App::Office::Contacts::Util::Config';

has log_object =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Log::Handler::Output::DBI',
	required => 0,
);

has simple =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'DBIx::Simple',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> module_config;
	my($attr)   =
	{
		AutoCommit => defined($$config{AutoCommit}) ? $$config{AutoCommit} : 1,
		RaiseError => defined($$config{RaiseError}) ? $$config{RaiseError} : 1,
	};
	my(%driver) =
	(
		mysql_enable_utf8 => qr/dbi:MySQL/i,
		pg_enable_utf8    => qr/dbi:Pg/i,
		sqlite_unicode    => qr/dbi:SQLite/i,
	);

	for my $db (keys %driver)
	{
		if ($$config{dsn} =~ $driver{$db})
		{
			$$attr{$db} = defined($$config{$db}) ? $$config{$db} : 1;
		}
	}

	$self -> simple(DBIx::Simple -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr) );
	$self -> simple -> query('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);
	$self -> log_object
	(
		Log::Handler::Output::DBI -> new
		(
			columns     => [qw/level message/],
			data_source => $$config{dsn},
			password    => $$config{password},
			persistent  => 1,
			table       => $$config{log_table_name} || 'log',
			user        => $$config{username},
			values      => [qw/%level %message/],
		)
	);

} # End of BUILD.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'info';
	$s     ||= '';

	$self -> log_object -> log(level => $level, message => $s);

} # End of log.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Logger - A web-based contacts manager

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

=item o log_object

Is an instance of a L<Log::Handler::Output::DBI>-based object.

=item o simple

Is an instance of an L<DBIx::Simple> object.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 log($level, $s)

Logs the message $s at the level $level.

=head2 log_object()

Returns an instance of a L<Log::Handler::Output::DBI>-based object.

=head2 simple()

Returns an instance of an L<DBIx::Simple> object.

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
