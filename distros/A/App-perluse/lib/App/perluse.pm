#!/usr/bin/perl -c

package App::perluse;

=head1 NAME

App::perluse - Use the specified perl in shell command

=head1 SYNOPSIS

  $ cpanm App::perluse

  $ perluse 5.30.0 perl -E 'say $^V'

  $ perluse blead perldoc perldelta

  $ perluse perl-5.30.0

  $ perluse

=head1 DESCRIPTION

See perluse(1) for available command line options.

C<App::perluse> is not real module because perluse(1) command is just a POSIX
shell script and it allows to install this script with cpan(1) or cpanm(1)
command.

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0301';


1;


=head1 INSTALLATION

=head2 With cpanm(1)

  $ cpanm App::perluse

=head2 Directly

  $ lwp-request http://git.io/dXVJCg | sh

or

  $ curl -kL http://git.io/dXVJCg | sh

or

  $ wget -O- http://git.io/dXVJCg | sh

=head1 ENVIRONMENT

The script sets C<VIRTUAL_ENV> and C<debian_chroot> environment variables so
shell prompt line should mark current Perl environment used.

=head1 SEE ALSO

L<http://github.com/dex4er/perluse>, perluse(1).

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2011-2014, 2020 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
