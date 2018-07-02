package App::cryp::Cmd::Exchange::create_limit_order;

our $DATE = '2018-06-24'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010;
use strict;
use warnings;

require App::cryp::exchange;

our %SPEC;

$SPEC{handle_cmd} = $App::cryp::exchange::SPEC{create_limit_order};
*handle_cmd = \&App::cryp::exchange::create_limit_order;

1;
# ABSTRACT: Create a limit order

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Cmd::Exchange::create_limit_order - Create a limit order

=head1 VERSION

This document describes version 0.010 of App::cryp::Cmd::Exchange::create_limit_order (from Perl distribution App-cryp-exchange), released on 2018-06-24.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

Create a limit order.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<base_size> => I<float>

Order amount, denominated in base currency (first currency of the pair).

=item * B<pair>* => I<str>

=item * B<price>* => I<float>

=item * B<quote_size> => I<float>

Order amount, denominated in quote currency (second currency of the pair).

=item * B<type>* => I<str>

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
