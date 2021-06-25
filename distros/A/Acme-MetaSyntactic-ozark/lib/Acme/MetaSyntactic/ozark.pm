package Acme::MetaSyntactic::ozark;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-21'; # DATE
our $DIST = 'Acme-MetaSyntactic-ozark'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: The Ozark theme

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::ozark - The Ozark theme

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::ozark (from Perl distribution Acme-MetaSyntactic-ozark), released on 2021-02-21.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=ozark -le 'print metaname'
 wendy

 % metasyn ozark --shuf -n2
 langmore
 jonah

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-ozark>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-ozark>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-MetaSyntactic-ozark/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Ozark_(TV_series)>,
L<https://en.wikipedia.org/wiki/List_of_Ozark_characters>

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
:all
# names first
marty wendy charlotte jonah ruth rachel roy camino jacob darlene wyatt helen ben maya mason buddy russ cade trevor charles
# names last
byrde langmore garrison petty delrio snell pierce davis miller young dieker evans wilkes
