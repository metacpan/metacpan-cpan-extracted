# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Link;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.12;



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub tag {
    my ($self) = @_;
    return $self->{tag};
}

sub relation {
    my ($self) = @_;
    return $self->{relation};
}

sub context {
    my ($self) = @_;
    return $self->{context};
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    foreach my $required (qw(db tag relation)) {
        croak 'Missing required member: '.$required unless defined $opts{$required};
    }

    return bless \%opts, $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Link - Work with Tag databases

=head1 VERSION

version v0.12

=head1 SYNOPSIS

    use Data::TagDB;

Parent package for L<Data::TagDB::Relation> and L<Data::TagDB::Metadata>.

=head1 METHODS

=head2 db

    my Data::TagDB $db = $db->db;

Returns the current L<Data::TagDB> object

=head2 tag, relation, context

    my Data::TagDB::Tag $db = $link->tag;
    my Data::TagDB::Tag $db = $link->relation;
    my Data::TagDB::Tag $db = $link->context;

Returns the corresponding tag, relation, or context. Returns undef if not set.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
