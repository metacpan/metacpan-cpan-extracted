# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Iterator;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.05;



sub new {
    my ($pkg, %opts) = @_;

    croak 'Missing required member: db' unless defined $opts{db};

    return bless \%opts, $pkg;
}


sub db {
    my ($self) = @_;
    return $self->{db};
}


sub next {
    my ($self) = @_;
    confess 'Not implemented';
}


sub finish {
    my ($self) = @_;
    confess 'Not implemented';
}



sub foreach {
    my ($self, $code) = @_;

    while (defined(my $ent = $self->next)) {
        $code->($ent);
    }

    $self->finish;
}


sub one {
    my ($self) = @_;
    my $ent = $self->next;
    $self->finish;

    return $ent // croak 'No entry';
}


sub collect {
    my ($self, $apply, %opts) = @_;
    my @ret;

    if (defined $apply) {
        unless (ref $apply) {
            my $funcname = $apply;
            $apply = sub { $_[0]->can($funcname)->(@_) };
        }
    }

    if (defined($apply)) {
        if ($opts{skip_died}) {
            while (defined(my $ent = $self->next)) {
                $ent = eval { $ent->$apply() };
                push(@ret, $ent) unless $@;
            }
        } else {
            while (defined(my $ent = $self->next)) {
                push(@ret, $ent->$apply());
            }
        }
    } else {
        while (defined(my $ent = $self->next)) {
            push(@ret, $ent);
        }
    }

    return \@ret if $opts{return_ref};

    return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Iterator - Work with Tag databases

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use Data::TagDB;

Generic iterator for database entries

=head1 METHODS

=head2 new

    my Data::TagDB::Iterator = XXX->new(...);

Returns a new iterator. Maybe called in sub-packages implementing actual iterators.

=head2 db

    my Data::TagDB $db = $db->db;

Returns the current Data::TagDB object

=head2 next

    my $entry = $iter->next;

Returns the next element or C<undef> when there is no next element.

Needs to be implemented.

=head2 finish

    $iter->finish;

Tells the iterator that you're done reading. May allow early freeing of backend data.

Needs to be implemented.

=head2 foreach

    $iter->foreach(sub {
        my ($entry) = @_;
        # ...
    });

Runs a function for each entry.
Automatically finishes the iterator.

=head2 one

    my $entry = $iter->one;

Returns one entry from the iterator and finishes.
This is most useful when you expect there to be exactly one entry.
This function dies if no entry is returned. So It is guaranteed that this function returns non-C<undef>.

=head2 collect

    my @list = $iter->collect;
    # or:
    my @list = $iter->collect('method');
    # or:
    my @list = $iter->collect(sub { ... });

Reads all entries from an iterator and finishes.
The entries are returned as a list.
Optionally a filter can be applied.
If the filter is a simple string it is as a method name to be called on the object.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
