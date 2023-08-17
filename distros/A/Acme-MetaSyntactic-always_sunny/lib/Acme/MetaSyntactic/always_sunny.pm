package Acme::MetaSyntactic::always_sunny;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-12'; # DATE
our $DIST = 'Acme-MetaSyntactic-always_sunny'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the sitcom It's Always Sunny In Philadephia (2005-)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::always_sunny - Characters from the sitcom It's Always Sunny In Philadephia (2005-)

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::always_sunny (from Perl distribution Acme-MetaSyntactic-always_sunny), released on 2023-03-12.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=always_sunny -le 'print metaname'
 charlie

 % meta always_sunny 2
 kelly
 mac

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-always_sunny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-always_sunny>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-always_sunny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
# default
:all
# names first
charlie mac rob dee dennis glenn wendell frank cricket matthew artemis waitress manager bonnie bill jack luther bill liam ryan maureen ben rex angel z chet carmen lefty barbara principal hwang gail brad jimmy shelley bruce schmitty ingrid
# names last
kelly reynolds albright mara ponderosa mcpoyle wallum macintyre doyle mathis nelson
