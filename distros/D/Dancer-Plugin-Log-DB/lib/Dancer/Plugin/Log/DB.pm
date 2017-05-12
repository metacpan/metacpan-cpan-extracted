package Dancer::Plugin::Log::DB;

use strict;
use warnings;

use Carp;
use List::Util 'first';
use Time::Piece;

use Dancer::Plugin;
use Dancer::Config;
use Dancer::Plugin::Database;

our $VERSION = '0.04';

our $settings = undef;
our $dbh;

my %db_defaults = (
	driver => 'SQLite',
	database => 'test',
	username => 'myusername',
	password => 'password',
	host => 'localhost',
	port => '3306',
);

sub _setup_connection {
	$settings = plugin_setting() if !$settings;
	return unless $settings;
	
	my %connection_params;
	
	for (qw/driver database username password host port/) {
		$connection_params{$_} = $settings->{database}{$_} || $db_defaults{$_};
	}
	
	$dbh = database(\%connection_params);
}

register log_db_dbh => sub {
	$dbh = _setup_connection() unless $dbh;
	return $dbh;
};

register log_db => sub {
	my $params = shift;

	_setup_connection();

	my $message_field_name = $settings->{log}->{message_field_name} || 'message';
	my $timestamp_field_name = $settings->{log}->{timestamp_field_name} || 'timestamp';

	my $logs_table_name = $settings->{log}->{logs_table_name} || 'logs';

	my $additional_fields = $settings->{log}->{additional_fields};

	my (@fields, @bind);

	my $message = $params->{message} || return;
	my $timestamp = $params->{timestamp} ? localtime($params->{timestamp}) : localtime;
	
	push @fields, $message_field_name;
	push @fields, $timestamp_field_name;
	push @bind, $message;
	push @bind, sprintf("%s %s", $timestamp->ymd, $timestamp->hms);
	
	# Handle additional field values
	delete $params->{message};
	delete $params->{timestamp};
	
	if (scalar %$params) {
		while (my ($key, $value) = each %$params) {
			unless (first { $_ eq $key } @$additional_fields) {
				Dancer::Logger::error("Non-described field: $key. Add it to 'additional_fields'");
				return;
			}

			push @fields, $key;
			push @bind, $value;
		}		
	}
		
	my $placeholders = join ",", map { "?" } @fields;
	my $query = "INSERT INTO ${logs_table_name} (" . join (",", @fields) . ") VALUES($placeholders)";

	my $sth = $dbh->prepare($query);
	$sth->execute(@bind);
};

register_plugin;

1; # End of Dancer::Plugin::Log::DB

__END__

=head1 NAME

Dancer::Plugin::Log::DB - log arbitrary messages into a database from within your Dancer application.

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

	use Dancer;
	use Dancer::Plugin::Log::DB;

	get '/' => sub {
		# Simple usage - timestamp is NOW 
		log_db { message => 'Simple log message' };

		# Both message and timestamp are set
		log_db { message => 'Message at certain time', timestamp => 9982481 };

		# Using additional fields for complementary information
		log_db { message => 'Another simple message', server_id => $my_server_id }; 
	}

Database connection details and plugin settings for logger are read from application config file - see below for more details.

=head1 DESCRIPTION

Provides an easy way to add arbitrary logging messages into a database for your Dancer application.
Supports more than one common field ('message') to add bits of information into.

You can add as many fields as you wish in your database table and fill them in with I<log_db> calls.

Default fields are I<message> and I<timestamp>, thus at its simplest case it requires database table with the following SQL declaration:

=over 4

=item * I<id> field.

Or any name you want - the plugin doesn't care of this field at all. Autoincrementing for this field would be a good choice.

=item * I<message> field.

This is where message will be stored. TEXT/VARCHAR type.

=item * I<timestamp> field.

Where timestamp field will be kept. TIMESTAMP/TEXT/VARCHAR type.

=back

You can expand functionality by adding any number of columns and write any data supported by your database backend.

For example, in complement to existing I<timestamp> and I<message> fields you can also add I<server_id> column to store server id which left the message.

=head1 CONFIGURATION

This plugin makes use of great I<Dancer::Plugin::Database> plugin, thus configuration is divided into 2 parts - database configuration and plugin configuration: 

	plugins:
		"Log::DB":
			database:
				driver: 'mysql'
				database: 'test'
				host: 'localhost'
				port: 3306
				username: 'logs_username'
				password: 'logs_password'
			log:
				logs_table_name: 'messages'
				message_field_name: 'message'
				timestamp_field_name: 'timestamp'
				additional_fields:
					- 'server_id'
					- 'author_id'

In the simplest case I<log> section can be empty. In this case table name should be called I<logs>, message field name should be I<message>, 
timestamp field name should be I<timestamp>. 

If you want to rename I<message> and I<timestamp> to something more clear in your database logs table, make sure you set corresponding names in I<message_field_name> and I<timestamp_field_name> under the I<log> section.

If you try to leave a log message in a field which is not listed within I<additional_fields>, you will get an error.

=head1 CAVEATS

=head1 BUGS

This is the 0.04 version and there are bugs. Your feedbacks are greatly welcome.

=head1 TODO

Add more tests for various database engines.

=head1 ACKNOWLEDGEMENTS

Thanks to David Precious for the L<Dancer::Plugin::Database> plugin.

Thanks to my wife for support.

=head1 AUTHOR

Nikolay Aviltsev, C<< navi@cpan.org >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nikolay Aviltsev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Dancer>

L<Dancer::Plugin::Database>

