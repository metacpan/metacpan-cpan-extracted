package Alien::Brotli;

# ABSTRACT: Download and install Brotli compressor

use v5.14;

use warnings;
use strict;

use base qw/ Alien::Base /;

use Path::Tiny qw/ path /;

use namespace::autoclean;

our $VERSION = 'v0.2.3';


sub exe {
    my ($self) = @_;
    return path( $self->bin_dir, $self->runtime_prop->{command} );
}


1;

__END__

=pod

=encoding UTF-8

=for stopwords exe

=head1 NAME

Alien::Brotli - Download and install Brotli compressor

=head1 VERSION

version v0.2.3

=head1 DESCRIPTION

This distribution installs C<brotli>, so that it can be used by other
distributions.

It does this by first trying to detect an existing installation.  If
found, it will use that.  Otherwise, the source will be downloaded
from the official git repository, and it will be installed in a
private share location for the use of other modules.

=head1 METHODS

=head2 exe

This returns the path to the C<brotli> executable, as a L<Path::Tiny>
object.

=head1 SEE ALSO

L<https://github.com/google/brotli>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Alien-Brotli>
and may be cloned from L<https://github.com/robrwo/perl-Alien-Brotli.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Alien-Brotli/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Robert Rothenberg <perl@rhizomnic.com>

=item *

Michal Josef Špaček <michal.josef.spacek@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022, 2026 by Robert Rothenberg.

This is free software, licensed under:

  The MIT (X11) License

=cut
