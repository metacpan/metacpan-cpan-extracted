package App::renlikewd;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-23'; # DATE
our $DIST = 'App-renlikewd'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: REName a file so it becomes LIKE the current (Working) Directory's name

__END__

=pod

=encoding UTF-8

=head1 NAME

App::renlikewd - REName a file so it becomes LIKE the current (Working) Directory's name

=head1 VERSION

This document describes version 0.005 of App::renlikewd (from Perl distribution App-renlikewd), released on 2023-11-23.

=head1 SYNOPSIS

See the command-line script L<renlikewd>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-renlikewd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-renlikewd>.

=head1 SEE ALSO

L<perlmv> (from L<App::perlmv>)

L<renwd> (from L<App::renwd>)

L<App::RenameUtils>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-renlikewd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
