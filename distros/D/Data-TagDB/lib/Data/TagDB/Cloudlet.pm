# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Cloudlet;

use v5.16;
use strict;
use warnings;

use Carp;

use Data::TagDB::Iterator;

our $VERSION = v0.10;



sub new {
    my ($pkg, %opts) = @_;
    my $root = delete($opts{root}) // [];
    my $entry = delete($opts{entry}) // [];

    croak 'No database given' unless defined $opts{db};

    $root = [$root] unless ref($root) eq 'ARRAY';
    $entry = [$entry] unless ref($entry) eq 'ARRAY';

    $opts{entries} = {
        (map {$_->dbid => undef} @{$entry}),
        (map {$_->dbid => 1} @{$root}),
    };

    return bless \%opts, $pkg;
}


sub db {
    my ($self) = @_;
    return $self->{db};
}


sub roots {
    my ($self) = @_;
    my Data::TagDB $db = $self->db;
    my $entries = $self->{entries};

    return map {$db->tag_by_dbid($_)} grep {$entries->{$_}} keys %{$entries};
}


sub entries {
    my ($self) = @_;
    my Data::TagDB $db = $self->db;
    my $entries = $self->{entries};

    return map {$db->tag_by_dbid($_)} keys %{$entries};
}


sub roots_iterator {
    my ($self) = @_;
    my @entries = $self->roots;
    return Data::TagDB::Iterator->from_array(\@entries, db => $self->db);
}


sub entries_iterator {
    my ($self) = @_;
    my @entries = $self->entries;
    return Data::TagDB::Iterator->from_array(\@entries, db => $self->db);
}


sub is_root {
    my ($self, $tag) = @_;
    return $self->{entries}{$tag->dbid};
}


sub is_entry {
    my ($self, $tag) = @_;
    return exists $self->{entries}{$tag->dbid};
}

# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Cloudlet - Work with Tag databases

=head1 VERSION

version v0.10

=head1 SYNOPSIS

    use Data::TagDB;
    use Data::TagDB::Cloudlet;

    my $db = Data::TagDB->new(...);

    my Data::TagDB::Cloudlet $cl = Data::TagDB::Cloudlet->new(db => $db, root => [...]);

This module implements cloudlets. A cloudlet is a collection of tags.

In a cloudlet each tag can only be once. Each tag has a boolean attached that indices if it is a root tag.
This is used to indicate if a tag is a first level member or was added by means of completion.

=head1 METHODS

=head2 new

    my Data::TagDB::Cloudlet $cl = Data::TagDB::Cloudlet->new(db => $db, root => [...]);

Creates a new cloudlet object.

The following options are supported:

=over

=item C<db>

The database to use. This is required.

=item C<root>

The root tag or tags. May be an arrayref of or single a L<Data::TagDB::Tag>.

=item C<entry>

Additional tags that are not root tags. May be an arrayref of or single a L<Data::TagDB::Tag>.

=back

=head2 db

    my Data::TagDB $db = $cl->db;

Returns the current L<Data::TagDB> object.

=head2 roots

    my @roots = $cl->roots;

Returns the list of root tags.

=head2 entries

    my @entries = $cl->entries;

Returns the list of all entries.

=head2 roots_iterator

    my Data::TagDB::Iterator $iter = $cl->roots_iterator;

Create an iterator for root entries.

=head2 entries_iterator

    my Data::TagDB::Iterator $iter = $cl->entries_iterator;

Create an iterator for all entries.

=head2 is_root

    my $bool = $cl->is_root($tag);

Returns whether or not a given tag is a root tag.

=head2 is_entry

    my $bool = $cl->is_entry($tag);

Returns whether or not a given tag is part of the cloudlet.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
