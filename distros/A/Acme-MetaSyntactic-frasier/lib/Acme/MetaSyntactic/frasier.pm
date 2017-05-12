package Acme::MetaSyntactic::frasier;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the sitcom Frasier (1993)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::frasier - Characters from the sitcom Frasier (1993)

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::frasier (from Perl distribution Acme-MetaSyntactic-frasier), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=frasier -le 'print metaname'
 eddie

 % meta frasier 2
 daly
 donny

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-frasier>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-frasier>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-frasier>

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
frasier daphne niles roz martin eddie bulldog kenny gil noel gertrude donny lilith james bebe mel ronee alice julia frederick simon lana sherry kirby charlotte kate
# names last
crane moon doyle briscoe daly chesterton shempsky douglas sternin glazer karnofsky lawrence wilcox gardner dempsey costas richman
