use strict;
use warnings;
package Alien::XInputSimulator;

# ABSTRACT: Perl distribution for XInputSimulator
our $VERSION = '0.001'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::XInputSimulator - Perl distribution for XInputSimulator

=head1 VERSION

version 0.001

=head1 INSTALL

    cpan Alien::XInputSimulator

=head1 DESCRIPTION

This Alien module wraps the XInputSimulator C++ library, a cross (X) Platform (Linux/Mac/Win) Simulator for input devices that simulates mouse moves/clicks/scrolls or keyboard keystrokes. It installs both static library for XS use as well as dynamic library for FFI.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-XInputSimulator>

=head1 SEE ALSO

L<https://github.com/pythoneer/XInputSimulator>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
