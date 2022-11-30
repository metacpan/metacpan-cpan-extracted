package Alien::psl;
# ABSTRACT: Discover or download and install psl (Public Suffix List Library)
use strict;
use warnings;

use base 'Alien::Base';

1;

__END__

=head1 NAME

Alien::psl

=head1 SYNOPSIS

    my $alien = Alien::psl->new;
    my $cflags = $alien->cflags;
    my $libs = $alien->libs;
    my $dynamic_libs = $alien->dynamic_libs;

The above methods are inherited from L<Alien::Base>.

If C<libpsl libpsl-dev> packages installed on your system, L<Alien::Base> will attempt to use the system version.
Otherwise it will download a latest from L<psl|https://github.com/rockdaboot/libpsl>.

=head1 DESCRIPTION

Discover or download and install L<psl|https://github.com/rockdaboot/libpsl>

=head1 AUTHOR

Yegor Korablev <egor@cpan.org>

=head1 LICENSE

The default license of psl is MIT.

=cut
