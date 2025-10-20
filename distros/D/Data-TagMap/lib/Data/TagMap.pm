# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for working with tag maps

package Data::TagMap;

use v5.10;
use strict;
use warnings;

use Carp;
use parent 'Data::Identifier::Interface::Userdata';

use Data::Identifier v0.19;

use constant {
    WK_HOST_DEFINED_IDENTIFIER => Data::Identifier->new(uuid => 'f8eb04ef-3b8a-402c-ad7c-1e6814cb1998'),
    NUMERICAL_TYPES => [map {Data::Identifier->new(sid => $_)}
        26, 27, 112, 113
    ],
};

our $VERSION = v0.01;



sub new {
    my ($pkg, @args) = @_;
    my $self = bless {
        individual => {},
        ranges => [],
    }, $pkg;

    croak 'Stray options passed' if scalar @args;

    return $self;
}


sub add_one {
    my ($self, $from, $to) = @_;
    $from = $self->_get_numerical_host_defined($from);

    unless (eval {$to->isa('Data::URIID::Colour')}) {
        $to = Data::Identifier->new(from => $to);
    }

    if (eval {$self->get('UNIVERSAL', $from)}) {
        croak 'Already mapped: '.$from;
    }

    $self->{individual}{$from} = $to;
}


sub add_range {
    my ($self, $from, $type, $to, %opts) = @_;
    my $length = int(delete($opts{length}) // 0);

    $from = $self->_get_numerical_host_defined($from);

    croak 'Stray options passed' if scalar keys %opts;
    croak 'No valid length given' if $length < 1;

    unless (eval{$type->isa('Data::Identifier')}) {
        $type = eval {Data::Identifier->new(wellknown => $type)} // Data::Identifier->new(from => $type);
    }

    if (ref $to) {
        $to = $to->as($type);
    }

    # TODO: Optimise this:
    for (my $idx = $from; $idx < ($from + $length); $idx++) {
        if (eval {$self->get('UNIVERSAL', $idx)}) {
            croak 'Already mapped: '.$idx;
        }
    }

    foreach my $numerical_type (@{NUMERICAL_TYPES()}) {
        if ($type->eq($numerical_type)) {
            push(@{$self->{ranges}}, {
                    from => $from,
                    end => $from+$length - 1,
                    type => $type,
                    to => $to,
                });
            return $self;
        }
    }

    croak 'Type not supported: '.$type->displayname;
}


sub get {
    my ($self, $as, @from) = @_;
    my @res;

    outer:
    foreach my $from (@from) {
        $from = $self->_get_numerical_host_defined($from);

        foreach my $range (@{$self->{ranges}}) {
            if ($from >= $range->{from} && $from <= $range->{end}) {
                my $id = $range->{to} + $from - $range->{from};

                push(@res, Data::Identifier->new($range->{type} => $id));
                next outer;
            }
        }

        if (defined(my $match = $self->{individual}{$from})) {
            push(@res, $match);
        } else {
            croak 'Entry '.$from.' not found';
        }
    }

    foreach my $res (@res) {
        $res = $res->Data::Identifier::as($as);
    }

    if (wantarray) {
        return @res;
    } elsif (scalar(@res) == 1) {
        return $res[0];
    } else {
        croak 'Invalid call';
    }
}

# ---- Private helpers ----

sub _get_numerical_host_defined {
    my ($self, $id) = @_;

    if (ref $id) {
        $id = Data::Identifier->new(from => $id);
        if ($id->type->eq(WK_HOST_DEFINED_IDENTIFIER)) {
            $id = $id->id;
        } else {
            croak 'Invalid identifier: '.$id;
        }
    }

    if ($id =~ /^~?(0|[1-9][0-9]*)$/) {
        $id = int $1;

        return $id if $id > 0;
    }

    croak 'Invalid identifier: '.$id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagMap - module for working with tag maps

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::TagMap;

This module implements a way to map between host defined tag identifiers and tags.

All methods in this module C<die> on error unless documented otherwise.

This module inherit from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my Data::TagMap $map = Data::TagMap->new;

Creates a new map object. No parameters are supported.

=head2 add_one

    $map->add_one($hdi => $to);

This method adds an entry for the given host defined identifier (C<$hdi>)
with the value C<$to>. C<$to> must be of any type supported by L<Data::Identifier/new> using C<from>.

=head2 add_range

    $map->add_range($from, $type, $to, length => $length);
    # e.g.:
    $map->add_range(100, sid => 1, length => 128);

Add a range to the map.
The range is defined using a starting poing (C<$from>), a starting identifier (C<$to> of type C<$type>), and a length (C<$length>).

C<$type> must be a L<Data::Identifier>, or value valid for C<wellknown> in L<Data::Identifier/new> or a UUID.
C<$type> must also be supported for ranges (it must be an identifier type that is numeric).

The range must not overlap with any other mappings.

=head2 get

    my $id  = $map->get($as, $hdi);
    # or:
    my @ids = $map->get($as, @hdi);

This method will return the entry for the given host defined identifier as an object of type C<$as>.

Valid values for C<$as> are those valid for the same parameter of L<Data::Identifier/as>.

B<Note:>
This method is sensitive to it's context (scalar or list).

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
