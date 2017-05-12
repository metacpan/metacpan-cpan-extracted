# ABSTRACT: Install and make available libotr v4 library

use strict;
use warnings;
package Alien::OTR;
our $AUTHORITY = 'cpan:AJGB';
$Alien::OTR::VERSION = '4.1.1.0';
use Alien::GCrypt;
use Alien::GPG::Error;

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::OTR - Install and make available libotr v4 library

=head1 VERSION

version 4.1.1.0

=head1 SYNOPSIS

    use Alien::OTR;

    my $cflags = Alien::OTR->cflags;
    my $libs = Alien::OTR->libs;

=head1 DESCRIPTION

Alien::OTR installs the C library C<libotr> version v4.1.1.

=head1 SEE ALSO

=over 4

=item * L<https://otr.cypherpunks.ca/>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
