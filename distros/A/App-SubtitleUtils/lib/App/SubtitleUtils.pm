package App::SubtitleUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-11'; # DATE
our $DIST = 'App-SubtitleUtils'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: Utilities related to video subtitles

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SubtitleUtils - Utilities related to video subtitles

=head1 VERSION

This document describes version 0.006 of App::SubtitleUtils (from Perl distribution App-SubtitleUtils), released on 2021-08-11.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<srtadjust>

=item * L<srtcalc>

=item * L<srtrenumber>

=item * L<srtscale>

=item * L<srtshift>

=item * L<srtsplit>

=item * L<subscale>

=item * L<subshift>

=item * L<vtt2srt>

=back

=head1 HISTORY

Most of them are scripts I first wrote in 2003 and first packaged as CPAN
distribution in late 2020. They need to be rewritten to properly use
L<Getopt::Long> etc; someday.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SubtitleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SubtitleUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SubtitleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

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

=cut
