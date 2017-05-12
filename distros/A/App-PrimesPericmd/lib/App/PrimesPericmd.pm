package App::PrimesPericmd;

our $DATE = '2016-09-28'; # DATE
our $VERSION = '0.001'; # VERSION

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

$SPEC{primes} = {
    v => 1.1,
    summary => 'Generate primes (Perinci::CmdLine-based version)',
    description => <<'_',

This version of `primes` utility uses the wonderful <pm:Math::Prime::Util> and
supports bigints.

_
    args => {
        start => {
            schema => 'int*',
            pos => 0,
            default => 2,
        },
        stop => {
            schema => 'int*',
            pos => 1,
        },
    },
    examples => [
        {
            summary => 'Generate primes',
            src => '[[prog]]',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate primes that are larger than 1000',
            src => '[[prog]] 1000',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate primes between 1000 to 2000',
            src => '[[prog]] 1000 2000',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 8,
        },
        {
            summary => 'Bigint support',
            src => '[[prog]] 18446744073709551616 18446744073709552000',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 8,
        },
    ],
    links => [
        {url => 'prog:primes'},
        {url => 'prog:primes.pl'},
    ],
};
sub primes {
    require Math::Prime::Util;

    my %args = @_;

    my $start = $args{start} // 2;
    my $stop  = $args{stop};
    my $bigint = do {
        # a method to check for the availability of 64bit integer, from:
        # http://www.perlmonks.org/?node_id=732199
        use bigint;
        if (eval { pack("Q", 65) }) {
            $start > 18446744073709551615;
        } else {
            $start > 4294967295;
        }
    };

    if (defined $stop) {
        my @res;
        if ($bigint) {
            use bigint;
            my $n = $start-1;
            while (1) {
                $n = Math::Prime::Util::next_prime($n);
                if ($n <= $stop) {
                    push @res, $n;
                } else {
                    last;
                }
            }
        } else {
            # XXX how to avoid code duplicate?
            my $n = $start-1;
            while (1) {
                $n = Math::Prime::Util::next_prime($n);
                if ($n <= $stop) {
                    push @res, $n;
                } else {
                    last;
                }
            }
        }

        # convert Math::BigInt objects into ints first, so the CLI formatter
        # detects it as simple aos
        for (@res) { $_ = $_->bstr if ref($_) eq 'Math::BigInt' }

        return [200, "OK", \@res];
    } else {
        # stream
        my $func;
        if ($bigint) {
            use bigint;
            my $n = $start-1;
            $func = sub {
                $n = Math::Prime::Util::next_prime($n);
                return ref($n) eq 'Math::BigInt' ? $n->bstr : $n;
            };
        } else {
            # XXX how to avoid code duplicate?
            my $n = $start-1;
            $func = sub {
                $n = Math::Prime::Util::next_prime($n);
                return ref($n) eq 'Math::BigInt' ? $n->bstr : $n;
            };
        }
        return [200, "OK", $func, {stream=>1}];
    }
}

1;
# ABSTRACT: Generate primes (Perinci::CmdLine-based version)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PrimesPericmd - Generate primes (Perinci::CmdLine-based version)

=head1 VERSION

This document describes version 0.001 of App::PrimesPericmd (from Perl distribution App-PrimesPericmd), released on 2016-09-28.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 primes(%args) -> [status, msg, result, meta]

Generate primes (Perinci::CmdLine-based version).

This version of C<primes> utility uses the wonderful L<Math::Prime::Util> and
supports bigints.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<start> => I<int> (default: 2)

=item * B<stop> => I<int>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-PrimesPericmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PrimesPericmd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PrimesPericmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Math::Prime::Util>


L<primes>.

L<primes.pl>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
