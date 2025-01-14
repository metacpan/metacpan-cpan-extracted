# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Relation;

use v5.10;
use strict;
use warnings;

use parent 'Data::TagDB::Link';

use Carp;

our $VERSION = v0.08;



sub filter {
    my ($self) = @_;
    return $self->{filter};
}

sub related {
    my ($self) = @_;
    return $self->{related};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Relation - Work with Tag databases

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::TagDB;

Package of relations. Inherits from L<Data::TagDB::Link>.

=head1 METHODS

=head2 filter, related

    my Data::TagDB::Tag $db = $link->filter;
    my Data::TagDB::Tag $db = $link->related;

Returns the corresponding filter, or related. Returns undef if not set.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
