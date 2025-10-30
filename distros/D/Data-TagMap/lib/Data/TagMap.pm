# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for working with tag maps

package Data::TagMap;

use v5.20;
use strict;
use warnings;

use Carp;
use parent 'Data::Identifier::Interface::Userdata';

use Data::Identifier v0.22;

use constant {
    WK_HOST_DEFINED_IDENTIFIER => Data::Identifier->new(uuid => 'f8eb04ef-3b8a-402c-ad7c-1e6814cb1998'),
    NUMERICAL_TYPES => [map {Data::Identifier->new(sid => $_)}
        26, 27, 112, 113
    ],
};

my %_valid_meta_ranges = map {$_ => undef} map {$_, $_.'_low', $_.'_mid', $_.'_high'} qw(sid sni raen chat0w colours unicodecp wd inode glyph individual);

our $VERSION = v0.02;



sub new {
    my ($pkg, @args) = @_;
    my $self = bless {
        individual => {},
        ranges => [],
        meta_ranges => {
            ANY => [0, undef, 1],
        },
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

    foreach my $meta_range (values %{$self->{meta_ranges}}) {
        $meta_range->[2]++ if ($meta_range->[2] // 0) == $from;
    }

    $self->{individual}{$from} = $to;
}


sub add_colours {
    my ($self, $from, @colours) = @_;

    require Data::URIID::Colour;

    foreach my $colour (@colours) {
        $colour = Data::URIID::Colour->new(rgb => $colour) unless ref $colour;

        $self->add_one($from, $colour);
        $from++;
    }
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

            foreach my $meta_range (values %{$self->{meta_ranges}}) {
                $meta_range->[2] += $length if ($meta_range->[2] // 0) == $from;
            }
            return $self;
        }
    }

    croak 'Type not supported: '.$type->displayname;
}


sub next_free {
    my ($self, $meta_range, @opts) = @_;
    my $next;
    my $last;

    croak 'Stray options passed' if scalar @opts;

    $meta_range //= 'ANY';
    $meta_range = $self->{meta_ranges}{$meta_range} // croak 'Invalide meta range: '.$meta_range;

    croak 'Meta range is not anchored' unless defined($meta_range->[0]) && defined($meta_range->[2]);

    $next = $meta_range->[2];
    $last = $meta_range->[0] + $meta_range->[1] if defined $meta_range->[1];

    while (defined(scalar eval {$self->get('UNIVERSAL', $next)})) {
        $next++;
        last if defined($last) && $next >= $last;
    }

    croak 'No space left' if defined($last) && $next >= $last;

    $meta_range->[2] = $next;

    return $next;
}


sub add_meta_range {
    my ($self, $name, %opts) = @_;
    my $start   = delete $opts{start};
    my $length  = delete $opts{length};
    my $end     = delete $opts{end};
    my $first;

    croak 'No name given' unless defined $name;
    croak 'Invalid meta range name: '.$name unless exists $_valid_meta_ranges{$name};

    croak 'Meta range already defined: '.$name if exists $self->{meta_ranges}{$name};

    croak 'Stray options passed' if scalar keys %opts;

    croak 'No start defined' unless defined $start;
    croak 'Start is invalid' unless $start > 0;

    if (defined($length) && defined($end)) {
        croak 'Length and end are both defined';
    }

    $length //= $end - $start + 1    if defined $end;
    $end    //= $start + $length - 1 if defined $length;

    croak 'Meta range has non-positive size' if defined($length) && $length < 1;

    $first = $start;
    $first = $self->{meta_ranges}{ANY}[2] if $self->{meta_ranges}{ANY}[2] > $first;

    $first = $end if defined($end) && $first > $end;

    $self->{meta_ranges}{$name} = [$start, $length, $first];

    return $self;
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


sub reverse_get {
    my ($self, @from) = @_;
    my @res;

    outer:
    foreach my $from (@from) {
        foreach my $idx (keys %{$self->{individual}}) {
            my $cand = $self->{individual}{$idx};
            if ($cand->as('Data::Identifier')->eq($from)) {
                push(@res, int($idx));
                next outer;
            }
        }

        foreach my $range (@{$self->{ranges}}) {
            for (my $idx = $range->{from}; $idx <= $range->{end}; $idx++) {
                my $cand = Data::Identifier->new($range->{type} => ($idx - $range->{from} + $range->{to}));
                if ($cand->eq($from)) {
                    push(@res, $idx);
                    next outer;
                }
            }
        }
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

version v0.02

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

=head2 add_colours

    $map->add_colours($hdi => @colours);

Adds zero or more colours to the map starting at host identifier C<$hdi>.

The colour values must be in C<#RRGGBB> format or any colour object accepted by L<Data::Identifier/new> using C<from>,
preferably a L<Data::URIID::Colour>.

=head2 add_range

    $map->add_range($from, $type, $to, length => $length);
    # e.g.:
    $map->add_range(100, sid => 1, length => 128);

Add a range to the map.
The range is defined using a starting poing (C<$from>), a starting identifier (C<$to> of type C<$type>), and a length (C<$length>).

C<$type> must be a L<Data::Identifier>, or value valid for C<wellknown> in L<Data::Identifier/new> or a UUID.
C<$type> must also be supported for ranges (it must be an identifier type that is numeric).

The range must not overlap with any other mappings.

=head2 next_free

    my $next_hdi = $map->next_free( [ $meta_range ] );

(since v0.02)

Finds the next free host defined identifier for the given meta range.
If no meta range is given C<ANY> is used.

This method will C<die> if no valid host defined identifier is found.

=head2 add_meta_range

    $map->add_meta_range($meta_ranges, %opts);

(experimental since v0.02)

Adds the meta range C<$meta_ranges> to the list.

The following options are supported:

=over

=item C<start>

The first host defined identifier in this meta range.
This option is required.

=item C<end>

The last host defined identifier in this meta range.
This option is optional.
This option cannot be given together with C<length>.

=item C<length>

The length of this meta range.
This option is optional.
This option cannot be given together with C<end>.

=back

B<Note:>
This method might or might not perform tests on the validity of the ranges.
Which tests are performed is subject change for future versions.

The following ranges are supported.
All ranges can be suffxed with C<_low>, C<_mid>, and C<_high>.
This is useful to split ranges if the target stores host defined identifiers in encodings with variable size.

=over

=item C<sid>

(since v0.02)

This meta range is for small-identifier mappings.
It is common to have the sid mapping as the first range so sids and host defined identifiers map to the same values.

=item C<sni>

(since v0.02)

This meta range is used to map SIRTX numerical identifiers.

=item C<raen>

(since v0.02)

This meta range is used to map RoarAudio error numbers, a type of portable error codes similar to errno.

=item C<chat0w>

(since v0.02)

This meta range is uded to map chat word tags.

=item C<colours>

(since v0.02)

This meta range is used to map colour values.

=item C<unicodecp>

(since v0.02)

This meta range is used to map unicode code points.
If C<unicodecp_low> is used it is common to have it map the full ASCII range (code points 0 to 127).

=item C<wd>

(since v0.02)

This meta range is used to map wikidata items (C<Q>, C<P>, and C<L> alike).

=item C<inode>

(since v0.02)

This meta range is used by filesystems or similar data structures. It is used to map to the inodes on the filesystem.
It is common that there is only one range that maps directly to all inodes, hence having the same or a larger size than the inode table.

=item C<glyph>

(since v0.02)

This meta range is used by fonts to map the individual glyphs.

=item C<individual>

(since v0.02)

This meta range is used for individual tags that are not part of any range.
See also L</add_range>.

=back

=head2 get

    my $id  = $map->get($as, $hdi);
    # or:
    my @ids = $map->get($as, @hdi);

This method will return the entry for the given host defined identifier as an object of type C<$as>.

Valid values for C<$as> are those valid for the same parameter of L<Data::Identifier/as>.

B<Note:>
This method is sensitive to it's context (scalar or list).

=head2 reverse_get

    my $hdi  = $map->reverse_get($as, $id);
    # or:
    my @hdis = $map->reverse_get($as, @ids);

(experimental since v0.02)

This method will return the host defined identifier for the given identifiers.

B<Note:>
This method is sensitive to it's context (scalar or list).

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
