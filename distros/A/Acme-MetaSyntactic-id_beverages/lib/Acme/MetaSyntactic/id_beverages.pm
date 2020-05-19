package Acme::MetaSyntactic::id_beverages;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-MetaSyntactic-id_beverages'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: The Indonesian beverages theme

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::id_beverages - The Indonesian beverages theme

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::id_beverages (from Perl distribution Acme-MetaSyntactic-id_beverages), released on 2020-03-01.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=id_beverages -le 'print metaname'
 semur

 % metasyn id_beverages | shuf | head -n2
 lodeh
 satay

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-id_beverages>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-id_beverages>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-id_beverages>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/List_of_Indonesian_drinks>

L<Acme::MetaSyntactic::id_dishes>

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
:all
# names beverages
bajigur bandrek tubrik tarik sekoteng serbat stmj talua wedang pletok dadiah
cendol cincau dawet goyobod doger siwalan puter lahang legen cukrik ciu tuak
sopi moke lapen
