package DB::Berkeley;

use strict;
use warnings;

use Exporter 'import';
require XSLoader;

=head1 NAME

DB::Berkeley - XS-based OO Berkeley DB HASH interface

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

our @EXPORT_OK = qw(DB_RDONLY);
use constant DB_RDONLY => 0x00000400;	# Must be the same as in db.h

XSLoader::load('DB::Berkeley', $VERSION);

=head1 DESCRIPTION

A lightweight XS wrapper around Berkeley DB using HASH format, without using tie().
DB_File works, I just prefer this API.

=head1 SYNOPSIS

    use DB::Berkeley;

    # Open or create a Berkeley DB HASH file
    my $db = DB::Berkeley->new("mydata.db", 0, 0666);

    # Store key-value pairs
    $db->put("alpha", "A");
    $db->put("beta",  "B");
    $db->put("gamma", "G");

    # Retrieve a value
    my $val = $db->get("beta");  # "B"

    # Check existence
    if ($db->exists("alpha")) {
        print "alpha is present\n";
    }

    # Delete a key
    $db->delete("gamma");

    # Get all keys (as arrayref)
    my $keys = $db->keys;        # returns arrayref
    my @sorted = sort @$keys;

    # Get all values (as arrayref)
    my $vals = $db->values;      # returns arrayref

    # Iterate using each-style interface
    $db->iterator_reset;
    while (my ($k, $v) = $db->each) {
        print "$k => $v\n";
    }

    # Use low-level iteration
    $db->iterator_reset;
    while (defined(my $key = $db->next_key)) {
        my $value = $db->get($key);
        print "$key: $value\n";
    }

    # Automatic cleanup when $db is destroyed

=head1 METHODS

=head2 new

    my $db = DB::Berkeley->new($filename, $flags, $mode, $sync_on_put);

Creates and opens a new Berkeley DB file.
If C<$sync_on_put> is true, every C<put()> will automatically call C<sync()> to flush to disk.

=head2 store($key, $value)

Alias for C<put>. Stores a key-value pair in the database.

=head2 set($key, $value)

Alias for C<set>. Stores a key-value pair in the database.

=head2 fetch($key)

Alias for C<get>. Retrieves a value for the given key.

=head2 iterator

    my $iter = $db->iterator;

Returns a L<DB::Berkeley::Iterator> object which can be used to iterate over
all key/value pairs in the database.

This allows you to write iterator-style loops:

    my $iter = $db->iterator;

    while (my $pair = $iter->each()) {
        my ($key, $value) = @{$pair};
        print "Key: $key, Value: $value\n";
    }

You can reset the iterator using:

    $iter->iterator_reset();

Note that calling C<each()> or other iteration methods directly on the C<$db> object
will use an internal cursor that is separate from the object returned by C<iterator()>.

This is especially useful for nested iteration or concurrent traversal contexts.

=head2 sync

    $db->sync();

Flushes all pending writes to disk.
Useful for ensuring durability between critical updates.

Returns true on success.
Croaks on error.

=head2 sync_on_put

    $db->sync_on_put(1);     # Enable syncing on put
    my $flag = $db->sync_on_put();  # Check current status

Get or set whether C<put()> operations immediately flush to disk via C<sync()>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<DB_File>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/DB-Berkeley>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-db-berkeley at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Berkeley>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc DB::Berkeley

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/DB-Berkeley>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Berkeley>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=DB-Berkeley>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=DB::Berkeley>

=back

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

1;
