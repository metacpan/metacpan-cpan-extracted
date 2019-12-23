package App::IMDBUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-22'; # DATE
our $DIST = 'App-IMDBUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

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

This document describes version 0.001 of App::IMDBUtils (from Perl distribution App-IMDBUtils), released on 2019-12-22.

=head1 DESCRIPTION

This distribution includes the following CLI utilities:

=over

=item * L<parse-imdb-title-page>

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

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
