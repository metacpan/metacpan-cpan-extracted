package Acme::MetaSyntactic::breaking_bad;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-12'; # DATE
our $DIST = 'Acme-MetaSyntactic-breaking_bad'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: Characters from the TV show Breaking Bad (2008-2013)

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::breaking_bad - Characters from the TV show Breaking Bad (2008-2013)

=head1 VERSION

This document describes version 0.001 of Acme::MetaSyntactic::breaking_bad (from Perl distribution Acme-MetaSyntactic-breaking_bad), released on 2023-03-12.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=breaking_bad -le 'print metaname'
 white

 % meta breaking_bad 2
 walter
 jesse

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-breaking_bad>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-breaking_bad>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-breaking_bad>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
# default
:all
# names first
walter skyler jesse marie hank saul steven mike gus skinny pete todd ted lydia badger george huell tyrus jane carmen andrea francesca tio victor brock gale jack kenny leonel frankie gratchen kuby bogdan combo marco kaylee lester matt tuco donald tim gaff chris elliott pamela gonzo wendy dennis juan tomas dan janice emilio tortuga spooge lawson sketchy barry
# names last
white pinkman schrader goodman gomez ehrmantraut fring beneke rodarte quayle merkert kitt margolis molina cantillo salamanca boetticher delcavoli schwartz wolynetz ramey roberts markowski bolsa kalanchoe wachsberger munn gardiner goodman
