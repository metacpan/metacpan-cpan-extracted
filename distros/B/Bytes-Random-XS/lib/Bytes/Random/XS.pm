#
# Copyright (C) 2017 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.24.0 or,
# at your option, any later version of Perl 5 you may have available.
#

package Bytes::Random::XS;

use strict;
use warnings;

use XSLoader;
use Exporter::Lite;

our $VERSION = '0.02';
our @EXPORT_OK = qw/random_bytes/;

XSLoader::load('Bytes::Random::XS', $VERSION);

'cravf';
__END__

=head1 NAME

Bytes::Random::XS - Perl extension to generate random bytes.

=head1 SYNOPSIS

    use Bytes::Random::XS qw/random_bytes/;

    my $bytes = random_bytes( $number_of_bytes );

=head1 DESCRIPTION

This module provides the C<random_bytes> function which allows you to
generate specified number of random bytes. It uses exactly the same
algorithm as L<Bytes::Random>, but it's implemented in XS, so it's
much faster (see L</BENCHMARKS> section).

=head1 BENCHMARKS

Comparison of L<Bytes::Random> and Bytes::Random::XS performance:

    # random_bytes(64)

                      Rate    B::R@0.02 B::R::X@0.01
    B::R@0.02      45903/s           --         -97%
    B::R::X@0.01 1462857/s        3087%           --

=head1 EXPORT

Nothing is exported by default. C<random_bytes> is an optional export.

=head1 CAVEATS

=over 4

=item *

This module is B<not> intended to be cryptographically secure. If that
concerns you, consider using L<Bytes::Random::Secure> instead.

=item *

L<Bytes::Random::XS> is an XS module, which means it's not compatible
with L<App::FatPacker>. L<Bytes::Random> is a pure Perl alternative
that doesn't have this problem.

=back

=head1 GIT REPOSITORY

Bytes::Random::XS repository is hosted at github:

    https://github.com/xenu/bytes-random-xs

=head1 SEE ALSO

=over 4

=item *

L<Bytes::Random> - pure Perl version of the module.

=item *

L<Bytes::Random::Secure> - cryptographically secure way to generate
random bytes.

=back

=head1 AUTHOR

    Tomasz Konojacki <me@xenu.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tomasz Konojacki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
