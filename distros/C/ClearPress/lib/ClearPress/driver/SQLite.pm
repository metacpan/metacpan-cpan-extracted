#########
# Author: rmp
# Created: 2006-10-31
#
package ClearPress::driver::SQLite;
use strict;
use warnings;
use base qw(ClearPress::driver);
use Carp;
use English qw(-no_match_vars);
use Readonly;

our $VERSION = q[476.4.2];

Readonly::Scalar our $TYPES => {
				'primary key' => 'integer primary key autoincrement',
				'char(128)'   => 'text',
			       };
sub dbh {
  my $self = shift;

  if(!$self->{dbh}) {
    my $dsn = sprintf q(DBI:SQLite:dbname=%s),
		      $self->{dbname}     || q[];

    eval {
      $self->{dbh} = DBI->connect($dsn, q[], q[],
				  {RaiseError => 1,
				   AutoCommit => 0});
    } or do {
      croak qq[Failed to connect to $dsn:\n$EVAL_ERROR];
    };

    #########
    # rollback any junk left behind if this is a cached handle
    #
    $self->{dbh}->rollback();
  }

  return $self->{dbh};
}


sub create {
  my ($self, $query, @args) = @_;
  my $dbh = $self->dbh();

  $dbh->do($query, {}, @args);

  my ($table)  = $query =~ /INTO\s+([[:lower:][:digit:]_]+)/smix;
  my $sequence = q[SELECT seq FROM sqlite_sequence WHERE name=?];
  my $idref    = $dbh->selectall_arrayref($sequence, {}, $table);

  return $idref->[0]->[0];
}

sub types {
  return $TYPES;
}

sub bounded_select {
  my ($self, $query, $len, $start) = @_;

  if(defined $start && defined $len) {
    $query .= qq[ LIMIT $start, $len];
  } elsif(defined $len) {
    $query .= qq[ LIMIT $len];
  }

  return $query;
}

1;
__END__

=head1 NAME

ClearPress::driver::SQLite - SQLite-specific implementation of the database abstraction layer

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 create

=head2 dbh

=head2 create_table

=head2 drop_table

=head2 types - the whole type map

=head2 bounded_select - select limited by number of rows and first-row position

  my $bounded_select = $driver->bounded_select($unbounded_select, $rows, $start_row);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::driver

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
