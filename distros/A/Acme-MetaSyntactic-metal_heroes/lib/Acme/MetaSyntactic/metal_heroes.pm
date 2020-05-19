package Acme::MetaSyntactic::metal_heroes;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-MetaSyntactic-metal_heroes'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: The Metal Heroes series theme

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::metal_heroes - The Metal Heroes series theme

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::metal_heroes (from Perl distribution Acme-MetaSyntactic-metal_heroes), released on 2020-03-01.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=metal_heroes -le 'print metaname'
 gavan

 % metasyn metal_heroes | shuf | head -n2
 juspion
 shaider

=head1 DESCRIPTION

TODO: enemies.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-metal_heroes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-metal_heroes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-metal_heroes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Metal_Hero_Series>

L<Acme::MetaSyntactic::gavan>

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
# names heroes
gavan sharivan shaider juspion spielban metalder jiraiya jiban winspector solbrain exceedraft janperson blueswat bfighter kabuto kabutack robotack
