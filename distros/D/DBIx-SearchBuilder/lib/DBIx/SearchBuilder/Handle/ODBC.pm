# $Header: /home/jesse/DBIx-SearchBuilder/history/SearchBuilder/Handle/ODBC.pm,v 1.8 2001/10/12 05:27:05 jesse Exp $

package DBIx::SearchBuilder::Handle::ODBC;

use strict;
use warnings;

use base qw(DBIx::SearchBuilder::Handle);

=head1 NAME

  DBIx::SearchBuilder::Handle::ODBC - An ODBC specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of DBIx::SearchBuilder::Handle that 
compensates for some of the idiosyncrasies of ODBC.

=head1 METHODS

=cut

=head2 CaseSensitive

Returns a false value.

=cut

sub CaseSensitive {
    my $self = shift;
    return (undef);
}

=head2 BuildDSN

=cut

sub BuildDSN {
    my $self = shift;
    my %args = (
	Driver     => undef,
	Database   => undef,
	Host       => undef,
	Port       => undef,
	@_
    );

    my $dsn = "dbi:$args{'Driver'}:$args{'Database'}";
    $dsn .= ";host=$args{'Host'}" if (defined $args{'Host'} && $args{'Host'});
    $dsn .= ";port=$args{'Port'}" if (defined $args{'Port'} && $args{'Port'});

    $self->{'dsn'} = $dsn;
}

=head2 ApplyLimits

=cut

sub ApplyLimits {
    my $self         = shift;
    my $statementref = shift;
    my $per_page     = shift or return;
    my $first        = shift;

    my $limit_clause = " TOP $per_page";
    $limit_clause .= " OFFSET $first" if $first;
    $$statementref =~ s/SELECT\b/SELECT $limit_clause/;
}

=head2 DistinctQuery

=cut

sub DistinctQuery {
    my $self         = shift;
    my $statementref = shift;
    my $sb = shift;

    $$statementref = "SELECT main.* FROM $$statementref";
    $$statementref .= $sb->_GroupClause;
    $$statementref .= $sb->_OrderClause;
}

sub Encoding {
}

1;

__END__

=head1 AUTHOR

Autrijus Tang

=head1 SEE ALSO

DBIx::SearchBuilder, DBIx::SearchBuilder::Handle

=cut
