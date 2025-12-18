# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Digest;

use strict;
use warnings;

use parent qw(Digest::base);

use Carp;

our $VERSION = v0.20;


# Private constructor:
sub _new {
    my ($pkg, $value) = @_;
    return bless \$value, $pkg;
}

sub new {
    croak 'Not implemented';
}

sub add {
    croak 'Not implemented';
}

# Just return ourselfs as we do not reset on digest read.
sub clone {
    return $_[0];
}

# Core digest method:
sub digest {
    my ($self) = @_;
    return pack('H*', ${$self});
}

# Helper to avoid pack()/unpack():
sub hexdigest {
    my ($self) = @_;
    return ${$self};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Digest - Extractor for identifiers from URIs

=head1 VERSION

version v0.20

=head1 SYNOPSIS

    use Data::URIID::Digest;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );
    my $digest = $result->digest('sha-3-512', as => 'Digest');

This is an internal module. It is used to emulate an object created by L<Digest>.

This module inherits from L<Digest::base>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
