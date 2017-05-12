package App::LinguaCommonUtils;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(%arg_words %arg_nums);

our %arg_words = (
    words => {
        'x.name.is_plural' => 1,
        schema => ['array*', of=>'str*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %arg_nums = (
    nums => {
        'x.name.is_plural' => 1,
        schema => ['array*', of=>'num*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

1;
# ABSTRACT: Common routines/data structures for App::LinguaXXUtils

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LinguaCommonUtils - Common routines/data structures for App::LinguaXXUtils

=head1 VERSION

This document describes version 0.05 of App::LinguaCommonUtils (from Perl distribution App-LinguaENUtils), released on 2016-01-18.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LinguaENUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LinguaENUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LinguaENUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
