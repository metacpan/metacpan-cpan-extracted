# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::WeakBaseObject;

use v5.10;
use strict;
use warnings;

use Scalar::Util qw(weaken);

use Carp;

our $VERSION = v0.12;


# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    weaken($opts{db}) if defined $opts{db};

    return bless \%opts, $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::WeakBaseObject - Work with Tag databases

=head1 VERSION

version v0.12

=head1 SYNOPSIS

    use Data::TagDB;

This is an interal package. See L<Data::TagDB>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
