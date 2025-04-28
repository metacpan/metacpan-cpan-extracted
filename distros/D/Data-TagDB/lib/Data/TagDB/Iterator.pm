# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Iterator;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.09;



sub new {
    my ($pkg, %opts) = @_;

    croak 'Missing required member: db' unless defined $opts{db};

    return bless \%opts, $pkg;
}


sub from_array {
    my ($pkg, $array, %opts) = @_;
    return Data::TagDB::Iterator::_Array->new(%opts, array => $array);
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


sub none {
    my ($self) = @_;
    my $ent = $self->next;

    $self->finish;

    croak 'Iterator non-empty' if defined $ent;
}


sub map {
    my ($self, $apply, %opts) = @_;

    return Data::TagDB::Iterator::_Mapped->new($self, $apply);
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

package Data::TagDB::Iterator::_Mapped {
    use parent -norequire, 'Data::TagDB::Iterator';

    sub new {
        my ($pkg, $parent, $apply) = @_;

        unless (ref $apply) {
            my $funcname = $apply;
            $apply = sub { $_[0]->can($funcname)->(@_) };
        }

        return $pkg->SUPER::new(db => $parent->db, parent => $parent, apply => $apply);
    }

    sub next {
        my ($self, @args) = @_;
        my $ent = $self->{parent}->next(@args);
        my $apply = $self->{apply};

        return undef unless defined $ent;

        return $ent->$apply();
    }

    sub finish {
        my ($self, @args) = @_;
        return $self->{parent}->finish(@args);
    }
};

package Data::TagDB::Iterator::_Array {
    use parent -norequire, 'Data::TagDB::Iterator';

    sub next {
        my ($self) = @_;
        $self->{index} //= 0;

        return $self->{array}[$self->{index}++];
    }

    sub finish {}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Iterator - Work with Tag databases

=head1 VERSION

version v0.09

=head1 SYNOPSIS

    use Data::TagDB;

Generic iterator for database entries

=head1 METHODS

=head2 new

    my Data::TagDB::Iterator $iter = XXX->new(...);

Returns a new iterator. Maybe called in sub-packages implementing actual iterators.

=head2 from_array

    my $Data::TagDB::Iterator $iter = Data::TagDB::Iterator->from_array(\@array, ...);

Creates an iterator from a simple array reference.
The reference becomes part of the object (so no copy is made).

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

=head2 none

    $iter->none;

This method dies if there is an entry left in the iterator.
This finishes the iterator.
This is most useful to assert that something is not present.

=head2 map

    my Data::TagDB::Iterator $mapped = $iter->map('method');
    # or:
    my Data::TagDB::Iterator $mapped = $iter->map(sub { ... });

Returns a new iterator that contains the entries mapped by a filter.
If the filter is a simple string it is as a method name to be called on the object.

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

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
