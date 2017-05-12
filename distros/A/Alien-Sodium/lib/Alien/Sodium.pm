# ABSTRACT: Install and make available libsodium library

use strict;
use warnings;
package Alien::Sodium;
our $AUTHORITY = 'cpan:AJGB';
$Alien::Sodium::VERSION = '1.0.8.0';
use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Sodium - Install and make available libsodium library

=head1 VERSION

version 1.0.8.0

=head1 SYNOPSIS

    use Alien::Sodium;

    my $cflags = Alien::Sodium->cflags;
    my $libs = Alien::Sodium->libs;

=head1 DESCRIPTION

Alien::Sodium installs the C library C<libsodium> version 1.0.8 released on
December 25, 2015.

=head1 SEE ALSO

=over 4

=item * L<libsodium|https://github.com/jedisct1/libsodium>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
