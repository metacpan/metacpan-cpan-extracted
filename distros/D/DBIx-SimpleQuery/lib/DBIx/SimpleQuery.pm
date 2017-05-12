##
## File: DBIx/SimpleQuery.pm
## Author: Steve Simms
##
## Revision: $Revision$
## Date: $Date$
##
## A module designed to take away the pain of querying the database.
##

package DBIx::SimpleQuery;

use Carp;
use DBI;
use DBIx::SimpleQuery::Object;

use strict;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(query qs);

our $VERSION = "0.05";

my $default_dsn;
my $default_user;
my $default_password;

my $debug = 0;

sub new {
    my ($class, %params) = @_;
    my $self = {};

    # A main goal of this module is to eliminate the need to specify
    # user and password if they can be derived.
    #
    # Try to get connection information from the following sources,
    # in decreasing order of preference:
    #
    # - Specified as arguments to query (defeats the point, but a
    #   useful override nonetheless)
    # - Given as parameters to new, which may be called explicitly by
    #   the module, instead of implicitly by query.
    if (keys %params) {
	$self->{"dsn"} = $params{"dsn"};
	$self->{"user"} = $params{"user"};
	$self->{"password"} = $params{"password"};
    }

    # - Stored as module-level variables
    elsif ($default_dsn) {
	$self->{"dsn"} = $default_dsn;
	$self->{"user"} = $default_user;
	$self->{"password"} = $default_password;
    }

    # - Stored as environment variables
    elsif ($ENV{"DBIX_SIMPLEQUERY_DSN"}) {
	$self->{"dsn"} = $ENV{"DBIX_SIMPLEQUERY_DSN"};
	$self->{"user"} = $ENV{"DBIX_SIMPLEQUERY_USER"};
	$self->{"password"} = $ENV{"DBIX_SIMPLEQUERY_PASSWORD"};
    }

    # - Read from /etc/simplequery.conf
    elsif (-r '/etc/simplequery.conf') {
	open my $config_file, '<', '/etc/simplequery.conf';
	while (<$config_file>) {
	    chomp;
	    my $line = $_;
	    
	    # Skip Comments
	    next if $line =~ /^\#/;

	    # Skip Blank Linkes
	    next if $line eq "";
	    next if $line =~ /^\s+$/;

	    # All remaining lines should be configuration values
	    unless ($line =~ /^\s*(dsn|user|password)\s*=\s*(\S+)\s*$/) {
		croak "Bad config file format: $line";
	    }
	    else {
		$self->{$1} = $2;
	    }
	}
    }

    # - Default to the first available data source of the first
    #   available driver of Oracle, Pg, or mysql, in that order, using
    #   the current user's login name, and no password.
    else {
	my @available_drivers = DBI->available_drivers();
	@available_drivers = grep { /^(?:Oracle|Pg|mysql)$/ } @available_drivers;
	my @data_sources = DBI->data_sources(shift @available_drivers);

	$self->{"dsn"} = shift(@data_sources);
	$self->{"user"} = getpwuid($>);
	$self->{"password"} = "";
    }

    return bless $self, $class;
}

sub setDefaults  { return set_defaults(@_); }
sub set_defaults {
    my %defaults = (ref($_[0]) eq "HASH" ? %{$_[0]} : @_);
    $default_dsn = $defaults{"dsn"} if exists $defaults{"dsn"};
    $default_user = $defaults{"user"} if exists $defaults{"user"};
    $default_password = $defaults{"password"} if exists $defaults{"password"};
    return;
}

sub getDsn  { return get_dsn(@_); }
sub get_dsn {
    my $self = shift();
    $self = new DBIx::SimpleQuery unless (ref($self) eq "DBIx::SimpleQuery");
    return $self->{"dsn"};
}

sub getUser  { return get_user(@_); }
sub get_user {
    my $self = shift();
    $self = new DBIx::SimpleQuery unless (ref($self) eq "DBIx::SimpleQuery");
    return $self->{"user"};
}

sub getPassword  { return get_password(@_); }
sub get_password {
    my $self = shift();
    $self = new DBIx::SimpleQuery unless (ref($self) eq "DBIx::SimpleQuery");
    return $self->{"password"};
}

# This can be called either as a class method or a function
sub query {
    my $self = shift();
    my $query;
    
    if (ref($self) eq "DBIx::SimpleQuery") {
	$query = shift();
    }
    else {
	$query = $self;
	$self = new DBIx::SimpleQuery(@_);
    }
    
    # Establish the connection
    my $dbh;
    if ($self->{"dsn"} =~ /^DBI:Pg/) {
        $dbh = DBI->connect_cached($self->{"dsn"}, $self->{"user"}, $self->{"password"}, {
            pg_server_prepare => 0,
        });
    }
    else {
        $dbh = DBI->connect_cached($self->{"dsn"}, $self->{"user"}, $self->{"password"});
    }
    croak "Unable to establish a database connection: $DBI::errstr" unless $dbh;

    # Debug
    print STDERR "SimpleQuery: $query\n" if $debug;
    
    # Prepare and execute the query
    my $sth = $dbh->prepare($query);
    my $rv  = $sth->execute();
    
    # Was the query successful?
    croak "Query error: " . $sth->errstr unless $rv;
    
    # Store the results
    my $object = new DBIx::SimpleQuery::Object {
	"count" => ($rv eq "0E0" ? 0 : $rv),
	"results" => ($sth->{"Active"} ? $sth->fetchall_arrayref({}) : []),
	"iter" => 0,
	"field_count" => $sth->{"NUM_OF_FIELDS"}
	};

    # Account for DBDs that don't set $rv to be the number of rows
    # returned.
    if (not $object->{"count"} and scalar @{$object->{"results"}}) {
	$object->{"count"} = scalar @{$object->{"results"}};
    }
    
    # Set the implicit variable
    $_ = $object;
    
    # List context returns different results depending on the type of
    # query
    if (wantarray) {
	my $first_row = $object->{"results"}->[0];
	
	# If only one field was retrieved, return an array of the values
	if ($object->{"field_count"} == 1) {
	    my @keys = keys %{$first_row};
	    my $key = shift(@keys);
	    return map { $_->{$key} } @{$object->{"results"}};
	}
	
	# Otherwise return an array of hashes containing the rows
	return @{$object->{"results"}};
    }

    # If there's only one row, and one field in that row, return the
    # value instead of a SimpleQuery object.
    if ($object->{"count"}       and $object->{"count"}       == 1 and
	$object->{"field_count"} and $object->{"field_count"} == 1) {
	my ($value) = values %{$object->{"results"}->[0]};
	return $value;
    }
    
    # In scalar or void context, return the object itself for further
    # interaction
    return $object;
}

# This can be called either as a class method or a function
sub qs {
    my $text;
    my $self;

    # It's possible to call this function without any arguments, in
    # which case it uses $_.
    if (scalar @_ == 0) {
	$self = new DBIx::SimpleQuery;
	$text = $_;
    }
    else {
	$self = shift();
	if (ref($self) eq "DBIx::SimpleQuery") {
	    $text = shift();
	}
	else {
	    $text = $self;
	    $self = new DBIx::SimpleQuery;
	}
    }
    
    return "NULL" unless defined $text;
    
    # Establish the connection
    my $dbh = DBI->connect_cached($self->{"dsn"}, $self->{"user"}, $self->{"password"});
    
    # If connection successfully established, use the driver's quote
    # method for best results.
    if ($dbh) {
	return $dbh->quote($text);
    }
    
    # Replace quotes with double-quotes
    $text =~ s/\'/\'\'/g;
    
    # Returned the escaped text within quotes
    return "'$text'";
}

1;

__END__

=head1 NAME

DBIx::SimpleQuery - Query databases using as little code as possible

=head1 SYNOPSIS

  use DBIx::SimpleQuery;
  
  DBIx::SimpleQuery::set_defaults(
      "dsn"      => "DBI:Pg:test_database",
      "user"     => "test_user",
      "password" => "test_password",
  );
  
  sub get_name {
      my $user_id = qs(shift());
      return query "SELECT name FROM users WHERE user_id = $user_id";
  }
  
  print get_name("mo'connor") . "\n";
  
  
  foreach my $name (query "SELECT name FROM users ORDER BY name") {
      print $name . "\n";
  }
  
  foreach my $row (query "SELECT user_id, name FROM users") {
      print $row->{"user_id"} . "\t" . $row->{"name"} . "\n";
  }
  

=head1 DESCRIPTION

DBIx::SimpleQuery is designed for anyone who wants to run specific SQL
commands against a database with as little surrounding structure as
possible.

It exports two functions, query and qs (quote-string), which allow you
to include SQL in your code without needing to deal with database
handlers, DSNs, and the like.

qs() escapes a string and surrounds it with single quotes, so that it
can be safely embedded in a query.  Whenever possible, it uses the
appropriate DBD module to do this.

query() runs one or more queries against a database, and returns a
value or a structure that can be evaluated in a number of ways,
depending on your need.

Multi-word functions may be called either in function_name or
functionName form, as per your preference.

=head2 Methods

=over 4

=item * new([%connection_defaults]);

Returns a DBIx::SimpleQuery object that allows you to reuse the same
connection properties in multiple queries.

If you pass a hash containing keys "dsn", "user", and "password",
these values will be used when making the database connection.

=item * qs($string)

Return a quoted and escaped version of $string.  Whenever possible, it
will use the appropriate DBD module's escape function.  If that is not
available, it replaces single quotes with two single quotes
(s{'}{''}g).

=item * query($query), $sql->query($query), query($query, %parameters)

Connect to the database and execute $query.  If only one row and
column are returned by the query, it will returned to the calling
function.  If only one column is returned, but there are multiple
rows, it will return an array of the values of that column.
Otherwise, a DBIx::SimpleQuery::Object will be returned containing the
results of the query.

If you pass in connection parameters (see the new method above), they
will be used instead of the defaults for this query.

=item * set_defaults(%connection_defaults)

Sets the default connection parameters for calls to query() and qs().
%connection_defaults should contain keys "dsn", "user", and
"password".  See the synopsis for an example.

=item * get_dsn()

=item * get_user()

=item * get_password()

Return the values that SimpleQuery intends to use for each parameter.

=back

=head1 AUTHOR

Steve Simms (ssimms@cpan.org)

=head1 COPYRIGHT

Copyright 2004 Steve Simms.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

DBI
DBIx::SimpleQuery::Object

=cut
