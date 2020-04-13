package App::IMDBUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-10'; # DATE
our $DIST = 'App-IMDBUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to IMDB (Internet Movie Database)',
};

1;
# ABSTRACT: Utilities related to IMDB (Internet Movie Database)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IMDBUtils - Utilities related to IMDB (Internet Movie Database)

=head1 VERSION

This document describes version 0.002 of App::IMDBUtils (from Perl distribution App-IMDBUtils), released on 2020-04-10.

=head1 DESCRIPTION

This distribution includes the following CLI utilities:

=over

=item * L<parse-imdb-title-page>

=item * L<search-imdb-title-id-by-title>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-IMDBUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IMDBUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IMDBUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
