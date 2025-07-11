package DB::Berkeley::Iterator

use strict;
use warnings;

require XSLoader;

=head1 NAME

DB::Berkeley::Iterator - Iterator for Berkeley DB key/value pairs

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

XSLoader::load('DB::Berkeley::Iterator', $VERSION);

=head1 SYNOPSIS

    use DB::Berkeley;

    my $db = DB::Berkeley->new("mydb.db", 0, 0600);

    my $iter = $db->iterator;

    while (my $pair = $iter->next) {
        my ($key, $value) = @$pair;
        print "$key => $value\n";
    }

    # Reset and iterate again
    $iter->iterator_reset;

    while (my $pair = $iter->next) {
        ...
    }

=head1 DESCRIPTION

C<DB::Berkeley::Iterator> provides an object-oriented interface for sequentially accessing
records in a Berkeley DB database. It allows full traversal of the database in key order and
can be reset to start iteration again.

=head1 METHODS

=head2 next

    my $pair = $iter->next;

Returns the next key/value pair as a two-element array reference.
When no more elements are available, returns undef.

=head2 iterator_reset

    $iter->iterator_reset;

Resets the iterator so that the next call to C<next> will return the first record
in the database.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
