package App::YtDlpUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-09'; # DATE
our $DIST = 'App-YtDlpUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities (mostly wrappers) related to yt-dlp',
};

1;
# ABSTRACT: Utilities (mostly wrappers) related to yt-dlp

__END__

=pod

=encoding UTF-8

=head1 NAME

App::YtDlpUtils - Utilities (mostly wrappers) related to yt-dlp

=head1 VERSION

This document describes version 0.001 of App::YtDlpUtils (from Perl distribution App-YtDlpUtils), released on 2024-07-09.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-YtDlpUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-YtDlpUtils>.

=head1 SEE ALSO

yt-dlp, L<https://github.com/yt-dlp/yt-dlp>

L<App::YouTubeUtils>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-YtDlpUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
