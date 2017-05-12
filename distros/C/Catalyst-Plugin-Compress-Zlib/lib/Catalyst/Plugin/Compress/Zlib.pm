package Catalyst::Plugin::Compress::Zlib;
use strict;
use warnings;
use base 'Catalyst::Plugin::Compress::Gzip';

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Catalyst::Plugin::Compress::Zlib - DEPRECATED Zlib Compression for Catalyst

=head1 SYNOPSIS

    use Catalyst qw[Compress::Zlib];
    # NOTE - DEPRECATED, supported for legacy applications,
    #        but use Catalyst::Plugin::Compress in new code.

=head1 DESCRIPTION

B<DEPRECATED> - supported for legacy applications, but useL<Catalyst::Plugin::Compress> in new code.

Compress response if client supports it.

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
