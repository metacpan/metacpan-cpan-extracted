package Acme::MetaSyntactic::schitts_creek;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-12'; # DATE
our $DIST = 'Acme-MetaSyntactic-schitts_creek'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the sitcom Schitt's Creek (2015-2020)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::schitts_creek - Characters from the sitcom Schitt's Creek (2015-2020)

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::schitts_creek (from Perl distribution Acme-MetaSyntactic-schitts_creek), released on 2023-03-12.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=schitts_creek -le 'print metaname'
 rose

 % meta 3rd_rock 2
 david
 johnny

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-schitts_creek>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-schitts_creek>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-schitts_creek>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
# default
:all
# names first
johnny moira david alexis roland stevie jocelyn twyla ronnie ted patrick bob mutt gwen grace ray wendy lena jake emir eric doris ivan clint bev tennesse don audrey
# names last
rose schitt budd sands lee mullens brewer currie butani kurtz kaplan taylor
