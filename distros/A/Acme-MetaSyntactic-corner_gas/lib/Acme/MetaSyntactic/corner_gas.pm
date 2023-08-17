package Acme::MetaSyntactic::corner_gas;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-12'; # DATE
our $DIST = 'Acme-MetaSyntactic-corner_gas'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the sitcom Corner Gas (2004-2009)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::corner_gas - Characters from the sitcom Corner Gas (2004-2009)

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::corner_gas (from Perl distribution Acme-MetaSyntactic-corner_gas), released on 2023-03-12.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=corner_gas -le 'print metaname'
 brent

 % meta corner_gas 2
 leroy
 hank

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-corner_gas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-corner_gas>.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-corner_gas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
# default
:all
# names first
brent lacey hank oscar emma davis karen wanda fitzy josh wes paul mertyl phil
# names last
leroy burrows yarbo quinton pelly dollard jensen humboldt kinistino runciman
