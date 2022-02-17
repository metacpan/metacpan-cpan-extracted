package BorderStyles::Test;

use strict;
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyles-Test'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: A collection of border styles, mainly for testing

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyles::Test - A collection of border styles, mainly for testing

=head1 VERSION

This document describes version 0.005 of BorderStyles::Test (from Perl distribution BorderStyles-Test), released on 2022-02-14.

=head1 BORDER STYLES

=over

=item * L<BorderStyle::Test::Random>

A border style that uses random characters.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyles-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyles-Test>.

=head1 SEE ALSO

L<BorderStyle> - specification

L<App::BorderStyleUtils> - CLIs

L<Text::Table::TinyBorderStyle>, L<Text::ANSITable> - some table renderers that can use border styles

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyles-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
