package App::FileSortUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-26'; # DATE
our $DIST = 'App-FileSortUtils'; # DIST
our $VERSION = '0.009'; # VERSION
1;

# ABSTRACT: CLI utilities related to sorting files in one or more directories

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileSortUtils - CLI utilities related to sorting files in one or more directories

=head1 VERSION

This document describes version 0.009 of App::FileSortUtils (from Perl distribution App-FileSortUtils), released on 2023-11-26.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item 1. L<foremost>

=item 2. L<hindmost>

=item 3. L<largest>

=item 4. L<longest-name>

=item 5. L<newest>

=item 6. L<oldest>

=item 7. L<shortest-name>

=item 8. L<smallest>

=item 9. L<sort-files>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileSortUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileSortUtils>.

=head1 SEE ALSO

L<App::DownloadsDirUtils>

L<File::Util::Sort> - the backend for most utilities in this distribution.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileSortUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
