use strict;
use warnings;
package Alien::HIDAPI;

# ABSTRACT: Perl distribution for HIDAPI
our $VERSION = '0.10'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::HIDAPI - Perl distribution for HIDAPI

=head1 INSTALL

    cpan Alien::HIDAPI

=head1 PLATFORMS
    
Same as HIDAPI proper: Linux, FreeBSD, macOS and Windows.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-HIDAPI>

=head1 SEE ALSO

L<HIDAPI|http://github.com/libusb/hidapi>

L<Alien>


=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
