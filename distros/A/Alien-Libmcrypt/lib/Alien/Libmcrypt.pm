package Alien::Libmcrypt;
# ABSTRACT: Install libmcrypt version 2.5.8
# KEYWORDS: mcrypt libmcrypt cryptography 
use strict;
use warnings;

1;

=pod

=encoding utf8

=head1 NAME

Alien::Libmcrypt

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    require Alien::Libmrypt;

=head1 DESCRIPTION

Alien::Libmrypt installs the C library C<libmcrypt> v2.5.8,which is a patched version of libmcrypt-2.5.8 with CTR and nCFB modes enabled and supports building on cygwin, mingw and msys.

=head1 SEE ALSO

=over 4

=item * L<https://osdn.net/projects/mcrypt/>

=back

=head1 AUTHOR

Li ZHOU <lzh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Li ZHOU <lzh@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
