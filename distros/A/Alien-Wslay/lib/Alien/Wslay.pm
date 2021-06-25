package Alien::Wslay;
# ABSTRACT: Discover or download and install Wslay
use strict;
use warnings;

use base 'Alien::Base';

1;

__END__

=head1 NAME

Alien::Wslay

=head1 SYNOPSIS

    my $alien = Alien::Wslay->new;
    my $cflags = $alien->cflags;
    my $libs = $alien->libs;
    my $dynamic_libs = $alien->dynamic_libs;

The above methods are inherited from L<Alien::Base>.

If C<libwslay1 libwslay-dev> packages installed on your system, L<Alien::Base> will attempt to use the system version.
Otherwise it will download a latest from L<Wslay|https://github.com/tatsuhiro-t/wslay>.

=head1 DESCRIPTION

Discover or download and install L<Wslay|https://github.com/tatsuhiro-t/wslay>

=head1 AUTHOR

Yegor Korablev <egor@cpan.org>

=head1 LICENSE

The default license of Wslay is MIT.

=cut
