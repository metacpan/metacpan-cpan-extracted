package App::GrepUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'App-GrepUtils'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: CLI utilities related to the Unix command 'grep'

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GrepUtils - CLI utilities related to the Unix command 'grep'

=head1 VERSION

This document describes version 0.005 of App::GrepUtils (from Perl distribution App-GrepUtils), released on 2021-11-14.

=head1 DESCRIPTION

This distribution includes the following CLI utilities related to the Unix
command C<grep>:

=over

=item * L<grep-terms>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GrepUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GrepUtils>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GrepUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
