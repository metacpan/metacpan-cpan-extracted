package App::YoutubeDlUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-13'; # DATE
our $DIST = 'App-YoutubeDlUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities (mostly wrappers) related to youtube-dl',
};

1;
# ABSTRACT: Utilities (mostly wrappers) related to youtube-dl

__END__

=pod

=encoding UTF-8

=head1 NAME

App::YoutubeDlUtils - Utilities (mostly wrappers) related to youtube-dl

=head1 VERSION

This document describes version 0.002 of App::YoutubeDlUtils (from Perl distribution App-YoutubeDlUtils), released on 2020-08-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-YoutubeDlUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-YoutubeDlUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-YoutubeDlUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

youtube-dl, L<https://youtube-dl.org>

L<App::YouTubeDlIf>

L<App::YouTubeUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
