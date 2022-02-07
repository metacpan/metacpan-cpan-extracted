package App::numseq;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'App-numseq'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

BEGIN {
    # this is a temporary trick to let Data::Sah use Scalar::Util::Numeric::PP
    # (SUNPP) instead of Scalar::Util::Numeric (SUN). SUNPP allows bigints while
    # SUN currently does not.
    $ENV{DATA_SAH_CORE_OR_PP} = 1;
}

our %SPEC;

$SPEC{numseq} = {
    v => 1.1,
    summary => 'Generate some number sequences',
    args => {
        name => {
            summary => 'Sequence name',
            schema => ['str*', {in=>[
                'fib', 'fibonacci',
                'squares',
                'fact', 'factorial',
            ]}],
            req => 1,
            pos => 0,
        },
        params => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'param',
            schema => ['array*', of=>'int*'],
            pos => 1,
            greedy => 1,
        },
    },
    examples => [
        {
            summary => 'Generate Fibonacci numbers',
            src => '[[prog]] fib 1 2',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url => 'prog:seq'},
        {url => 'prog:seq-pericmd'},
        {url => 'prog:primes'},
        {url => 'prog:primes.pl'},
        {url => 'prog:primes-pericmd'},
    ],
};
sub numseq {
    use bigint;

    my %args = @_;

    my $name = $args{name};
    my $params = $args{params} // [];

    my $func;
    if ($name eq 'fib' || $name eq 'fibonacci') {
        return [400, "Please supply 2 starting numbers"]
            unless @$params == 2;
        my ($a, $b) = @$params;
        my $i = 0;
        $func = sub {
            $i++;
            my $res;
            if ($i == 1) {
                $res = $a;
            } elsif ($i == 2) {
                $res = $b;
            } else {
                $res = $a+$b;
                $a = $b;
                $b = $res;
            }
            return ref($res) eq 'Math::BigInt' ? $res->bstr : $res;
        };
    } elsif ($name eq 'squares') {
        #return [400, "Please supply at most one starting number"]
        #    unless @$params <= 1;
        return [400, "Extra parameters not allowed"] if @$params;
        my $i = $params->[0] // 1;
        $func = sub {
            my $res;
            $res = $i*$i;
            $i++;
            return ref($res) eq 'Math::BigInt' ? $res->bstr : $res;
        };
    } elsif ($name eq 'fact' || $name eq 'factorial') {
        #return [400, "Please supply at most one starting number"]
        #    unless @$params <= 1;
        return [400, "Extra parameters not allowed"] if @$params;
        my $i = $params->[0] // 1;
        my $res;
        $func = sub {
            if ($i == 1) {
                $res = $i;
            } else {
                $res *= $i;
            }
            $i++;
            return ref($res) eq 'Math::BigInt' ? $res->bstr : $res;
        };
    }
    return [200, "OK", $func, {stream=>1}];
}

1;
# ABSTRACT: Generate some number sequences

__END__

=pod

=encoding UTF-8

=head1 NAME

App::numseq - Generate some number sequences

=head1 VERSION

This document describes version 0.002 of App::numseq (from Perl distribution App-numseq), released on 2021-08-01.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 numseq

Usage:

 numseq(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate some number sequences.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>

Sequence name.

=item * B<params> => I<array[int]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-numseq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-numseq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-numseq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

These modules also have "numseq" in them, but they are only tangentially
related: L<NumSeq::Iter>, L<App::seq::numseq>, L<Sah::Schemas::NumSeq>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
