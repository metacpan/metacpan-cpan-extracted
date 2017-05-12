#!perl

use strict;
use warnings;

package DBIx::Iterator::Statement;
{
  $DBIx::Iterator::Statement::VERSION = '0.0.2';
}

# ABSTRACT: Query your database using iterators and save memory

use Carp qw(confess);


sub new {
    my ($class, $query, $db) = @_;
    confess("Please specify a database query") unless defined $query;
    confess("Please specify a database iterator factory") unless defined $db;
    my $sth = $db->dbh->prepare($query);
    return bless {
        'sth'   => $sth,
        'db'    => $db,
    }, $class;
}


sub db {
    my ($self) = @_;
    return $self->{'db'};
}


sub sth {
    my ($self) = @_;
    return $self->{'sth'};
}


## no critic (Subroutines::RequireArgUnpacking)
sub bind_param {
    my $self = shift;
    return $self->sth->bind_param(@_);
}
## use critic


## no critic (Subroutines::RequireArgUnpacking)
sub execute {
    my $self = shift;
    $self->sth->execute(@_);
## use critic
    return sub {
        my $row = $self->sth->fetchrow_hashref();
        return $row, $self if wantarray;
        return $row;
    };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBIx::Iterator::Statement - Query your database using iterators and save memory

=head1 VERSION

version 0.0.2

=head1 METHODS

=head2 new($query, $db)

Creates a database statement object that can be used to bind parameters and
execute the query.

=head2 db

Returns the database object specified in the constructor.

=head2 sth

Returns the DBI statement handle associated with the prepared statement.

=head2 bind_param(@args)

Specifies bind parameters for the query as defined in L<DBI/bind_param>.

=head2 execute(@placeholder_values)

Executes the prepared query with the optional placeholder values.  Returns a
code reference you can execute until it is exhausted.  If called in list
context, it will also return a reference to the statement object itself.
The iterator returns exactly what L<DBI/fetchrow_hashref> returns.  When the
iterator is exhausted it will return undef.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
