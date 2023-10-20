package Acme::MetaSyntactic::not_going_out;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-12'; # DATE
our $DIST = 'Acme-MetaSyntactic-not_going_out'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the britcom Not Going Out (2006-)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::not_going_out - Characters from the britcom Not Going Out (2006-)

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::not_going_out (from Perl distribution Acme-MetaSyntactic-not_going_out), released on 2023-03-12.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=not_going_out -le 'print metaname'
 lee

 % meta not_going_out 2
 lucy
 lee

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-not_going_out>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-not_going_out>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-not_going_out>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
# default
:all
# names first
lee lucy daisy tim toby morris wendy anna geoffrey mollie molly frank benji charlie barbara kate lola jack flo chris stuart debbie amy paul stretch george ruth rachel kerry
# names last
shaffington anstis moss
