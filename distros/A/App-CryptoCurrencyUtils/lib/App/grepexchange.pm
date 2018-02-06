package App::grepexchange;

our $DATE = '2018-02-05'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

gen_modified_sub(
    output_name => 'grep_exchange',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Grep cryptocurrency exchanges',
    description => <<'_',

Greps list of cryptocurrency exchanges from <pm:CryptoExchange::Catalog>, which
in turn gets its list from <https://coinmarketcap.com/>.

_
    remove_args => ['pattern'],
    modify_args => {
        regexps => sub {
            my $arg = shift;
            $arg->{pos} = 0;
            $arg->{greedy} = 1;
        },
        ignore_case => sub {
            my $arg = shift;
            $arg->{default} = 1;
        },
    },
    output_code => sub {
        require CryptoExchange::Catalog;

        my %args = @_;

        my @exchanges;
        my $cat = CryptoExchange::Catalog->new;
        for ($cat->all_data) {
            push @exchanges, "$_->{name}\n";
        }

        $args{_source} = sub {
            if (@exchanges) {
                return (shift(@exchanges), undef);
            } else {
                return;
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Grep cryptocurrency exchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::grepexchange - Grep cryptocurrency exchanges

=head1 VERSION

This document describes version 0.010 of App::grepexchange (from Perl distribution App-CryptoCurrencyUtils), released on 2018-02-05.

=head1 FUNCTIONS


=head2 grep_exchange

Usage:

 grep_exchange(%args) -> [status, msg, result, meta]

Grep cryptocurrency exchanges.

Greps list of cryptocurrency exchanges from L<CryptoExchange::Catalog>, which
in turn gets its list from L<https://coinmarketcap.com/>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Require all patterns to match, instead of just one.

=item * B<color> => I<str>

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<ignore_case> => I<bool> (default: 1)

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<quiet> => I<true>

=item * B<regexps> => I<array[re]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CryptoCurrencyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CryptoCurrencyUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CryptoCurrencyUtils>

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
