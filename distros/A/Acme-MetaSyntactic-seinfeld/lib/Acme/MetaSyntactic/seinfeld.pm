package Acme::MetaSyntactic::seinfeld;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the sitcom Seinfeld (1989)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::seinfeld - Characters from the sitcom Seinfeld (1989)

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::seinfeld (from Perl distribution Acme-MetaSyntactic-seinfeld), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=seinfeld -le 'print metaname'
 elaine

 % meta seinfeld 2
 kramer
 newman

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-seinfeld>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-seinfeld>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-seinfeld>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
:all
# names first
jerry kramer george elaine ruthie susan estelle frank helen jacopo morty leo matt david justin mickey kenny russell tim joe carol jackie sue
# names last
seinfeld costanza benes cohen newman ross peterman wilhelm lippman puddy pitt dugan bania dalrymple whatley davola chiles kruger ellen
