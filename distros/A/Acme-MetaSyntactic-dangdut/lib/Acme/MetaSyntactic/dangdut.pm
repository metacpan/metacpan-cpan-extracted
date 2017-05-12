package Acme::MetaSyntactic::dangdut;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: A selection of popular Indonesian dangdut singers

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::dangdut - A selection of popular Indonesian dangdut singers

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::dangdut (from Perl distribution Acme-MetaSyntactic-dangdut), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=dangdut -le 'print metaname'
 rhoma

 % meta dangdut 2
 gotik
 cita

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-dangdut>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-dangdut>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-dangdut>

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
rhoma elvy rita cita mansyur hamdan meggy muchsin itje jaja camelia iis evie mega vety cucu cici lilis nini fitri annisa juwita inul alam ria zaskia ayu jenita alam
# names last
irama sukaesih sugiarto citata alatas trisnawati miharja malik dahlia tamala mustika vera cahyati paramida karlina carlina bahar daratista amelia gotik tingting janet
