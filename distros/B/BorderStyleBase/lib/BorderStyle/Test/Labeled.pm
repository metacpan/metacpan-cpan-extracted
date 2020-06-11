package BorderStyle::Test::Labeled;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'A border style that uses labeled characters as described in specification',
    chars => [                 # y
        # 0    1    2    3 <-- x
        ['A', 'b', 'C', 'D'],  # 0
        ['E', 'F', 'G'],       # 1
        ['H', 'i', 'J', 'K'],  # 2
        ['L', 'M', 'N'],       # 3
        ['O', 'p', 'Q', 'R'],  # 4
        ['S', 't', 'U', 'V'],  # 5
    ],
);

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::Labeled

=head1 VERSION

This document describes version 0.002 of BorderStyle::Test::Labeled (from Perl distribution BorderStyleBase), released on 2020-06-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyleBase>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
