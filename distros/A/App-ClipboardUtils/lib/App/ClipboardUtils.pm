package App::ClipboardUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-13'; # DATE
our $DIST = 'App-ClipboardUtils'; # DIST
our $VERSION = '0.007'; # VERSION

1;
# ABSTRACT: CLI utilities related to clipboard

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ClipboardUtils - CLI utilities related to clipboard

=head1 VERSION

This document describes version 0.007 of App::ClipboardUtils (from Perl distribution App-ClipboardUtils), released on 2023-04-13.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to clipboard:

=over

=item 1. L<add-clipboard-content>

=item 2. L<clear-clipboard-content>

=item 3. L<clear-clipboard-history>

=item 4. L<clipadd>

=item 5. L<clipget>

=item 6. L<detect-clipboard-manager>

=item 7. L<get-clipboard-content>

=item 8. L<get-clipboard-history-item>

=item 9. L<list-clipboard-history>

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

This software is copyright (c) 2023, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ClipboardUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
