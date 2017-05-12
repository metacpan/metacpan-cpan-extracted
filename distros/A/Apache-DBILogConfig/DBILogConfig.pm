package Apache::DBILogConfig;

require 5.004;

use strict;

# MODULES

use mod_perl 1.11_01;
use Apache::Constants qw( :common );
use DBI;
use Date::Format;

$Apache::DBILogConfig::VERSION = "0.02";

# List of allowed formats and their values
my %Formats = 
  (
	 'a' => sub {return (shift)->connection->remote_ip}, # Remote IP Address
	 'A' => sub {}, # Local IP-address
	 'b' => sub {return (shift)->bytes_sent || '-'}, # Bytes sent, excluding heaers, in CLF format
	 'B' => sub {return (shift)->bytes_sent}, # Bytes sent, excluding heaers
	 'c' => sub {}, # Connection status when response is completed (X, +, -)
   'e' => sub {return (shift)->subprocess_env(shift)}, # Any environment variable
   'f' => sub {return (shift)->filename}, # Filename
   'h' => sub {return (shift)->get_remote_host}, # Remote host
   'H' => sub {return (shift)->protocol}, # The request protocol
   'i' => sub {return (shift)->header_in(shift)}, # A header in the client request
   'l' => sub {return (shift)->get_remote_logname}, # Remote log name (from identd)
   'm' => sub {return (shift)->method}, # The request method
   'n' => sub {return (shift)->notes(shift)}, # The contents of a note from another module
   'o' => sub {return (shift)->header_out(shift)}, # A header from the reply
   'p' => sub {return (shift)->get_server_port}, # Server port
   'P' => sub {return $$}, # Apache child PID
	 'q' => sub {return $_[0]->args ? '?' . $_[0]->args : ''}, # The query string (prepended with a ?
	                                                             # if the query exists)
   'r' => sub {return (shift)->the_request}, # First line of the request
   's' => sub {return (shift)->status}, # Status
   't' => sub {return time2str $_[1] || "%d/%b/%Y:%X %z", $_[0]->request_time}, # Time: CLF or strftime
   'T' => sub {return time - (shift)->request_time}, # Time taken to serve the request
   'u' => sub {return (shift)->connection->user}, # Remote user from auth
   'U' => sub {return (shift)->uri}, # URL
   'v' => sub {return (shift)->server->server_hostname}, # The canonical ServerName
   'V' => sub {} # The UseCanonicalName server name
  );

# SUBS

sub logger {

  my $r = shift;
  $r = $r->last; # Handle internal redirects
  $r->subprocess_env; # Setup the environment

  # Connect to the database
  my $source = $r->dir_config('DBILogConfig_data_source');
  my $username = $r->dir_config('DBILogConfig_username');
  my $password = $r->dir_config('DBILogConfig_password');
  my $dbh = DBI->connect($source, $username, $password);
  unless ($dbh) { 
    $r->log_error("Apache::DBILogConfig could not connect to $source - $DBI::errstr");
    return DECLINED;
  } # End unless
  $r->warn("DBILogConfig: Connected to $source as $username");

  # Parse the formats ( %[conditions]{param}format=field [...] )
  my @format_list = (); # List of anon hashes {field, format, param, conditions}
	my $format_string = Apache->request->dir_config('DBILogConfig_log_format');
	while ($format_string =~ /%(!)?([^\{[:alpha:]]*)(?:\{([^\}]+)\})?(\w)=(\S+)/g) {
		my ($op, $conditions, $param, $format, $field) = ($1, $2, $3, $4, $5);

		# Or conditions together
    my @conditions = map q($r->status ==  ) . $_, split /,/, $conditions;
    $conditions = join(' or ', @conditions);

    $conditions = qq{!($conditions)} if $op eq '!'; # Negate if necessary
    $conditions ||= 1; # If no conditions we want a guranteed true condition
    $r->warn("DBILogConfig: format=$format, field=$field, param=$param, conditions=$conditions");
    push @format_list, {'field' => $field, 'format' => $format, 'param' => $param, 
												'conditions' => $conditions};
  } # End foreach

  # Create the statement and insert data
  my $table = $r->dir_config('DBILogConfig_table');
  @format_list = grep eval $_->{'conditions'}, @format_list; # Keep only ones whose conditions are true
  my $fields = join ', ', map $_->{'field'}, @format_list; # Create string of fields
  my $values = join ', ', map $dbh->quote($Formats{$_->{'format'}}->($r, $_->{'param'})), @format_list; # Create str of values
  my $statement = qq(INSERT INTO $table ($fields) VALUES ($values));
  $r->warn("DBILogConfig: statement=$statement");
  $dbh->do($statement);

  $dbh->disconnect;

  return OK;

} # End logger

sub handler {shift->post_connection(\&logger)}

1;

__END__

=head1 NAME

Apache::DBILogConfig - Logs access information in a DBI database

=head1 SYNOPSIS

 # In httpd.conf
 PerlLogHandler Apache::DBILogConfig
 PerlSetVar DBILogConfig_data_source DBI:Informix:log_data
 PerlSetVar DBILogConfig_username    informix
 PerlSetVar DBILogConfig_password    informix
 PerlSetVar DBILogConfig_table	     mysite_log
 PerlSetVar DBILogConfig_log_format  "%b=bytes_sent %f=filename %h=remote_host %r=request %s=status"

=head1 DESCRIPTION

This module replicates the functionality of the standard Apache module, mod_log_config,
but logs information in a DBI-compliant database instead of a file. (Some documentation has been
borrowed from the mod_log_config documentation.)

=head1 LIST OF TOKENS

=over 4

=item DBILogConfig_data_source

A DBI data source with a format of "DBI::driver:database"

=item DBILogConfig_username

Username passed to the database driver when connecting

=item DBILogConfig_password

Password passed to the database driver when connecting

=item DBILogConfig_table

Table in the database for logging

=item DBILogConfig_log_format

A string consisting of formats separated by white space that define the data to be logged (see FORMAT STRING below)

=back

=head1 FORMAT STRING

A format string consists of a string with the following syntax:

B<%[conditions][{parameter}]format=field>

=head2 format

Formats specify the type of data to be logged. The following formats are accepted:

=over

=item a Remote IP-address

=item A Local IP-address (not yet supported)

=item B Bytes sent, excluding HTTP headers.

=item b Bytes sent, excluding HTTP headers. In CLF format
        i.e. a '-' rather than a 0 when no bytes are sent.

=item c Connection status when response is completed.
        'X' = connection aborted before the response completed.
        '+' = connection may be kept alive after the response is sent.
        '-' = connection will be closed after the response is sent.
        (not yet supported)

=item e The contents of the environment variable specified by parameter

=item f Filename

=item h Remote host

=item H The request protocol

=item i The contents of the header (specified by parameter) in the request sent to the server.

=item l Remote logname (from identd, if supplied)

=item m The request method

=item n The contents of note (specified by parameter) from another module.

=item o The contents of the header (specified by parameter) in the reply.

=item p The canonical Port of the server serving the request

=item P The process ID of the child that serviced the request.

=item q The query string (prepended with a ? if a query string exists, otherwise an empty string)

=item r First line of request

=item s Status. For requests that got internally redirected, this is the status of
        the *original* request.

=item t Time, in common log format time format or the format specified by parameter, 
        which should be in strftime(3) format.

=item T The time taken to serve the request, in seconds.

=item u Remote user (from auth; may be bogus if return status (%s) is 401)

=item U The URL path requested.

=item v The canonical ServerName of the server serving the request.

=item V The server name according to the UseCanonicalName setting (not yet supported).

=back

=head2 field

A database column to log the data to

=head2 parameter

For formats that take a parameter

Example: %{DOCUMENT_ROOT}e 

=head2 conditions

Conditions are a comma-separated list of status codes. If the status of the request being logged equals one of 
the status codes in the condition the data specified by the format will be logged. By placing a '!' in front of
the conditions, data will be logged if the request status does not match any of the conditions.

Example: %!200,304,302s=status will log the status of all requests that did not return some sort of normal status

=head1 DEBUGGING

Debugging statements will be written to the error log if LOGLEVEL is set to 'warn' or higher

=head1 PREREQUISITES

=over

=item * mod_perl >= 1.11_01 with PerlLogHandler enabled

=item * DBI

=item * Date::Format

=back

=head1 INSTALLATION

To install this module, move into the directory where this file is
located and type the following:

        perl Makefile.PL
        make
        make test
        make install

This will install the module into the Perl library directory. 

Once installed, you will need to modify your web server's configuration as above.

=head1 NOTE

After installing and configuring this module, Apache will continue to log to your regular
access log file (if it was previously configured that way). To log accesses only to your database
comment out CustomLog or TransferLog or set them to /dev/null.

=head1 AUTHOR

Copyright (C) 1998, Jason Bodnar <jason@shakabuku.org>. All rights reserved.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), mod_perl(3)

=cut
