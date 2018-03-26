use strict;
use warnings;
package Alien::libudev;

# ABSTRACT: Perl distribution for libudev
our $VERSION = '0.14'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::libudev - Perl distribution for libudev

=for html <a href="https://travis-ci.org/athreef/Alien-libudev"><img src="https://travis-ci.org/athreef/Alien-libudev.svg?branch=master"></a>

=head1 INSTALL

    cpan Alien::libudev

=head1 eudev

Apparently, you can't build libudev separately from systemd anymore.
Some Gentoo developers have forked udev as eudev, with the aim of keeping
it isolated from systemd. This is what this module builds.

If you prefer systemd's libudev, install it over your distro's package
manager. e.g. on Debian:

    sudo apt-get install libudev-dev

Installing this module on a system with systemd's libudev is effectively
a no-op.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-libudev>

=head1 SEE ALSO

L<https://github.com/gentoo/eudev>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
