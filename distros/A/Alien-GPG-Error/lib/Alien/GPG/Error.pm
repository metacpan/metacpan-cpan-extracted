# ABSTRACT: Install and make available libgpg-error

use strict;
use warnings;
package Alien::GPG::Error;
our $AUTHORITY = 'cpan:AJGB';
$Alien::GPG::Error::VERSION = '1.21.0';
use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::GPG::Error - Install and make available libgpg-error

=head1 VERSION

version 1.21.0

=head1 SYNOPSIS

    use Alien::GPG::Error;

    my $cflags = Alien::GPG::Error->cflags;
    my $libs = Alien::GPG::Error->libs;

=head1 DESCRIPTION

Alien::GPG::Error installs the C library C<libgpg-error> v1.21.

=head1 SEE ALSO

=over 4

=item * L<https://www.gnupg.org/related_software/libgpg-error/index.html>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
