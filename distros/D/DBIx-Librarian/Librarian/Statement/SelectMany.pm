package DBIx::Librarian::Statement::SelectMany;

require 5.005;
use strict;
use base qw(DBIx::Librarian::Statement);
use vars qw($VERSION);
$VERSION = '0.4';

=head1 NAME

DBIx::Librarian::Statement::SelectMany - multi-row SELECT statement

=head1 DESCRIPTION

SELECT statement that expects to retrieve multiple (zero or more)
rows from the database.

All values fetched will be stored in arrays in the data hash, either as

    $data->{node}[0]->{column}
    $data->{node}[1]->{column}

or as

    $data->{column}[0]
    $data->{column}[1]

depending on how the output column names are specified in the SQL.

=cut

sub fetch {
    my ($self, $data) = @_;

    my $i = 0;
    while (my $hash_ref = $self->{STH}->fetchrow_hashref) {
	while (my ($key, $val) = each %$hash_ref) {
	    if ($key =~ /\./) {
		my ($obj, $subkey) = split /\./, $key;
		$data->{$obj}[$i]->{$subkey} = $val;
	    } else {
		$data->{$key}[$i] = $val;
	    }
	}
	$i++;
	last if $i >= $self->{MAXSELECTROWS};
    }

    return $i;
}


1;

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
