package DBIx::Librarian::Statement::SelectOne;

require 5.005;
use base qw(DBIx::Librarian::Statement);
use strict;
use Carp;
use vars qw($VERSION);
$VERSION = '0.4';

=head1 NAME

DBIx::Librarian::Statement::SelectOne - non-strict single-row SELECT statement

=head1 DESCRIPTION

SELECT statement that expects to retrieve exactly one record from
the database, but might find none.  An exception is raised if
more than one row is found.

By default, all values fetched will be stored in top-level scalars
in the data hash.  If ALLARRAYS is set, results will be stored as
element zero in a list for each field.

=cut

sub fetch {
    my ($self, $data) = @_;

    my $hash_ref = $self->{STH}->fetchrow_hashref;
    if (!$hash_ref) {
#	print STDERR "...no matching rows\n";
	return 0;
    }

    while (my ($key, $val) = each %$hash_ref) {
	my $node = $data;

	if ($key =~ /\./) {
	    my ($base, $subkey) = split /\./, $key;
	    $node->{$base} = {} unless defined $node->{$base};
	    $node = $node->{$base};
	    $key = $subkey;
	}

	if ($self->{ALLARRAYS}) {
	    $node->{$key}[0] = $val;
	} else {
	    $node->{$key} = $val;
	}
    }

    if ($self->{STH}->fetchrow_hashref) {
	croak "Expected exactly one row; received more than one for\n" . $self->{STH}->{Statement} . "\n";
    }

    return 1;
}


1;

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
