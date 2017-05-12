# ABSTRACT: Install and make available libgcrypt

use strict;
use warnings;
package Alien::GCrypt;
our $AUTHORITY = 'cpan:AJGB';
$Alien::GCrypt::VERSION = '1.6.5.0';
use Alien::GPG::Error;

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::GCrypt - Install and make available libgcrypt

=head1 VERSION

version 1.6.5.0

=head1 SYNOPSIS

    use Alien::GCrypt;

    my $cflags = Alien::GCrypt->cflags;
    my $libs = Alien::GCrypt->libs;

=head1 DESCRIPTION

Alien::GCrypt installs the C library C<libgcrypt> v1.6.5.

=head1 SEE ALSO

=over 4

=item * L<https://www.gnu.org/software/libgcrypt/>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
