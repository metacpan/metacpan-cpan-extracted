package BorderStyle::Test::CustomChar;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-06'; # DATE
our $DIST = 'BorderStyleBase'; # DIST
our $VERSION = '0.009'; # VERSION

use strict;
use warnings;
use parent 'BorderStyleBase';

our %BORDER = (
    v => 2,
    summary => 'A border style that uses a single custom character',
    args => {
        character => {
            schema => 'str*',
            req => 1,
        },
    },
    examples => [
        {
            summary => "Use x as the border character",
            args => {character=>"x"},
        },
    ],
);

sub get_border_char {
    my ($self, $y, $x, $n, $args) = @_;
    $n = 1 unless defined $n;

    $self->{args}{character} x $n;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::CustomChar

=head1 VERSION

This document describes version 0.009 of BorderStyle::Test::CustomChar (from Perl distribution BorderStyleBase), released on 2021-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyleBase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyleBase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-BorderStyleBase/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
