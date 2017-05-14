package DBIx::Retry;
use parent qw(DBIx::Connector);
# ABSTRACT: DBIx::Connector with the ability to retry the run method for a specified amount of time.

use strict;
use warnings;
#modules
use Moo;
use Try::Tiny;

has retry_time => (is => 'rw', required => 1);
has verbose => (is => 'rw', default => sub { return 1 });

before run => sub {
	my $self = shift;
	my $i = 1;
	$self->_try_connect;
	while (! $self->connected) {
		warn "DBIx::Retry retry $i\n" if $self->verbose;
		sleep(1);
		$self->_try_connect;
		last if $i >= $self->retry_time;
		$i++;
	}	
};

sub _try_connect {
	my $self = shift;
	try {	
		$self->dbh;		#connect to the database
	}
}

sub BUILDARGS {
	my $self = shift;
	my ($dsn,$user,$pass,$args) = @_;
	return $args;
} 	
1;




=pod

=head1 NAME

DBIx::Retry - DBIx::Connector with the ability to retry the run method for a specified amount of time.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use DBIx::Retry;
  my $conn = DBIx::Retry->new($dsn, $user, $tools, {retry_time => 5});
	
  # all other method are inherited from DBIx::Connector
  my $dbh = $conn->dbh;  #get a database handle
	
  # Do something with the handle - will retry for specified amount of time, should the database connection be lost
  $conn->run(fixup => sub {
    $_->do('INSERT INTO foo (name) VALUES (?)', undef, 'Fred' );
  });

=head1 DESCRIPTION

DBIx::Retry is extended from DBIx::Connector. It adds the ability to keep retrying to connect to a database for a specified amount of time in order to execute DBIx::Connector's run method.

=head1 ATTRIBUTES

=head2 retry_time

  Amount of seconds to retry re-connecting to database, should the database become unavailable. 

=head2 verbose

  Enable verbose output.

=head1 METHODS

=head2 new

Create a new DBIx::Retry object.
	my $conn = DBIx::Retry->new($dsn, $user, $tools,{timeout => 5, verbose => 1});

=head1 USAGE

Simply create a new DBIx::Retry object:

  my $conn = DBIx::Retry->new($dsn, $user, $tools, {retry_time => 5});

Then wrap your operations inside the run method that is inherited from DBIx::Connector:

  $conn->run(fixup => sub {
    $_->do('INSERT INTO foo (name) VALUES (?)', undef, 'Fred' );
  });

Should the connection to the database be lost then DBIx::Retry will retry to connect to the database for the amount of	seconds specified in the "retry_time" attribute.

=head1 SEE ALSO

DBIx::Connector

=head1 AUTHOR

Hartmut Behrens <hartmut.behrens@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hartmut Behrens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__