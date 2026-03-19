package Alien::libwebsockets;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

sub has_extensions {
    my ($class) = @_;
    my @libs = $class->dynamic_libs;
    return 0 unless @libs;

    my @nm_cmd = $^O eq 'darwin'                              ? ('nm', '-gU')
               : $^O =~ /^(?:freebsd|openbsd|netbsd|dragonfly)$/ ? ('nm', '-g')
               :                                                    ('nm', '-D');

    foreach my $lib (@libs) {
        my $found = 0;
        if (open my $fh, '-|', @nm_cmd, $lib) {
            while (<$fh>) {
                if (/lws_extension_callback_pm_deflate/) { $found = 1; last }
            }
            close $fh;
        }
        return 1 if $found;
    }

    return 0;
}

1;

__END__

=head1 NAME

Alien::libwebsockets - Find or build libwebsockets C library

=head1 SYNOPSIS

    use Alien::libwebsockets;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        ...
        CONFIGURE_REQUIRES => {
            'Alien::libwebsockets' => 0,
        },
        CCFLAGS => Alien::libwebsockets->cflags,
        LIBS    => Alien::libwebsockets->libs,
    );

=head1 DESCRIPTION

This module provides the libwebsockets C library. It will either
use the system library if available, or download and build it from source.

When built from source, libwebsockets is configured with libev, SSL,
zlib, and permessage-deflate extension support.

=head1 METHODS

Inherits all methods from L<Alien::Base> and implements the following.

=head2 has_extensions

    my $bool = Alien::libwebsockets->has_extensions;

Returns true if the installed libwebsockets includes permessage-deflate
extension support. Uses C<nm> for symbol detection. Only reliable for
C<share> installs; returns false for C<system> installs where the shared
library path is not tracked.

=head1 SEE ALSO

L<Alien::Base>, L<libwebsockets|https://libwebsockets.org/>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
