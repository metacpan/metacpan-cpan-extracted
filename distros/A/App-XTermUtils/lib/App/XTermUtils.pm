package App::XTermUtils;

our $DATE = '2018-09-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{get_term_bgcolor} = {
    v => 1.1,
    summary => 'Get terminal background color',
    args => {},
};
sub get_term_bgcolor {
    require XTerm::Util;

    my %args = @_;

    [200, "OK", XTerm::Util::get_term_bgcolor()];
}

$SPEC{set_term_bgcolor} = {
    v => 1.1,
    summary => 'Set terminal background color',
    args => {
        rgb => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
};
sub set_term_bgcolor {
    require XTerm::Util;

    my %args = @_;

    XTerm::Util::set_term_bgcolor($args{rgb});
    [200, "OK"];
}

1;
# ABSTRACT: Utilities related to XTerm

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XTermUtils - Utilities related to XTerm

=head1 VERSION

This document describes version 0.001 of App::XTermUtils (from Perl distribution App-XTermUtils), released on 2018-09-25.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<get-term-bgcolor>

=item * L<set-term-bgcolor>

=back

=head1 FUNCTIONS


=head2 get_term_bgcolor

Usage:

 get_term_bgcolor() -> [status, msg, result, meta]

Get terminal background color.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 set_term_bgcolor

Usage:

 set_term_bgcolor(%args) -> [status, msg, result, meta]

Set terminal background color.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<rgb>* => I<color::rgb24>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-XTermUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-XTermUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XTermUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
