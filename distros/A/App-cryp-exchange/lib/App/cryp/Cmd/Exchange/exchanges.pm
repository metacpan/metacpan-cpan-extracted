package App::cryp::Cmd::Exchange::exchanges;

our $DATE = '2018-06-13'; # DATE
our $VERSION = '0.009'; # VERSION

use 5.010;
use strict;
use warnings;

require App::cryp::exchange;

our %SPEC;

$SPEC{handle_cmd} = $App::cryp::exchange::SPEC{exchanges};
*handle_cmd = \&App::cryp::exchange::exchanges;

1;
# ABSTRACT: List supported exchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Cmd::Exchange::exchanges - List supported exchanges

=head1 VERSION

This document describes version 0.009 of App::cryp::Cmd::Exchange::exchanges (from Perl distribution App-cryp-exchange), released on 2018-06-13.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

List supported exchanges.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-exchange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
