package Apache::SessionX::Generate::Random;

use 5.006;

use strict;
use warnings;

use Apache::Session::Generate::Random;

our $VERSION = '0.002002';

# ABSTRACT: use system randomness for generating session ids


BEGIN {
  *generate = \&Apache::Session::Generate::Random::generate;
  *validate = \&Apache::Session::Generate::Random::validate;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache::SessionX::Generate::Random - use system randomness for generating session ids

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    use Apache::SessionX::Generate::Random;
    $id = Apache::SessionX::Generate::Random::generate($string);

=head1 DESCRIPTION

This module extends L<Apache::SessionX> to create secure random session ids using the system's source of randomness.

=for Pod::Coverage generate

=for Pod::Coverage validate

=head1 SEE ALSO

L<Apache::SessionX>

L<Crypt::SysRandom>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module should work on very old Perl versions, such as v5.6.0.
However, only Perl versions released in the last ten years will be supported.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Apache-Session-Generate-Random/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Apache-Session-Generate-Random>
and may be cloned from L<https://github.com/robrwo/perl-Apache-Session-Generate-Random.git>

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
