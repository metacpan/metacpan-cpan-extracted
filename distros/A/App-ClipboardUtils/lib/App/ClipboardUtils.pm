package App::ClipboardUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-08'; # DATE
our $DIST = 'App-ClipboardUtils'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: CLI utilities related to clipboard

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ClipboardUtils - CLI utilities related to clipboard

=head1 VERSION

This document describes version 0.006 of App::ClipboardUtils (from Perl distribution App-ClipboardUtils), released on 2022-12-08.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to clipboard:

=over

=item * L<add-clipboard-content>

=item * L<clear-clipboard-content>

=item * L<clear-clipboard-history>

=item * L<clipadd>

=item * L<clipget>

=item * L<detect-clipboard-manager>

=item * L<get-clipboard-content>

=item * L<list-clipboard-history>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ClipboardUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ClipboardUtils>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ClipboardUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
