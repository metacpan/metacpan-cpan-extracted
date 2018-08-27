package App::ISBNUtils;

our $DATE = '2018-08-23'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{format_isbn10} = {
    v => 1.1,
    summary => 'Format ISBN 10, print error if number is invalid',
    description => <<'_',

You can feed an ISBN 13 and it will be converted to ISBN 10 (as long as the ISBN
13 prefix is 978-).

_
    args => {
        isbn10 => {
            schema => 'isbn10*',
            req => 1,
            pos => 0,
        },
    },
};
sub format_isbn10 {
    my %args = @_;
    [200, "OK", $args{isbn10}];
}

$SPEC{format_isbn13} = {
    v => 1.1,
    summary => 'Format ISBN 13, print error if number is invalid',
    description => <<'_',

You can feed an ISBN 10 and it will be converted to ISBN 13.

_
    args => {
        isbn13 => {
            schema => 'isbn13*',
            req => 1,
            pos => 0,
        },
    },
};
sub format_isbn13 {
    my %args = @_;
    [200, "OK", $args{isbn13}];
}

1;
# ABSTRACT: Command-line utilities related to ISBN

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ISBNUtils - Command-line utilities related to ISBN

=head1 VERSION

This document describes version 0.002 of App::ISBNUtils (from Perl distribution App-ISBNUtils), released on 2018-08-23.

=head1 DESCRIPTION

This distribution contains the following command-line utilities related to ISBN:

=over

=item * L<format-isbn10>

=item * L<format-isbn13>

=back

=head1 FUNCTIONS


=head2 format_isbn10

Usage:

 format_isbn10(%args) -> [status, msg, result, meta]

Format ISBN 10, print error if number is invalid.

You can feed an ISBN 13 and it will be converted to ISBN 10 (as long as the ISBN
13 prefix is 978-).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<isbn10>* => I<isbn10>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 format_isbn13

Usage:

 format_isbn13(%args) -> [status, msg, result, meta]

Format ISBN 13, print error if number is invalid.

You can feed an ISBN 10 and it will be converted to ISBN 13.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<isbn13>* => I<isbn13>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ISBNUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ISBNUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ISBNUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<isbn> from L<App::isbn>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
