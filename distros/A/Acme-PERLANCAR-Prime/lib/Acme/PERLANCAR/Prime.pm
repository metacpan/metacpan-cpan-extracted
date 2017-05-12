package Acme::PERLANCAR::Prime;

our $DATE = '2016-09-23'; # DATE
our $DIST = 'Acme-PERLANCAR-Prime'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use integer;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(primes);

my @primes = (2);

sub _empty_cache {
    @primes = (2);
}

sub _is_prime {
    my $num = shift;
    my $sqrt = $num**0.5;
    for my $i (0..$#primes) {
        my $fact = $primes[$i];
        last if $fact > $sqrt;
        return 0 if $num % $fact == 0;
    }
    1;
}

sub primes {
    my ($base, $num);

    if (@_ > 1) {
        ($base, $num) = @_;
    } else {
        $base = 1;
        $num = $_[0];
    }

    my @res;
    my $i = $base;
    $i = 2 if $i < 2;

    # first, fill with precomputed primes
    my $k = -1;
    for my $j (0..$#primes) {
        my $p = $primes[$j];
        if ($p >= $i && $p <= $num) {
            push @res, $p;
            $i = $p + 1;
            $k = $j;
        }
    }

    while ($i <= $num) {
        if (_is_prime($i)) {
            push @primes, $i;
            push @res, $i;
        }
        $i++;
        $i++ if $i % 2 == 0; # quick skip even numbers
    }
    @res;
}

1;
# ABSTRACT: Return prime numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Prime - Return prime numbers

=head1 VERSION

This document describes version 0.001 of Acme::PERLANCAR::Prime (from Perl distribution Acme-PERLANCAR-Prime), released on 2016-09-23.

=head1 DESCRIPTION

This distribution is created for testing only.

=head1 FUNCTIONS

=head2 primes([ $base, ] $num) => list

Return prime numbers (from C<$base> if specified) that are less or equal to
C<$num>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Prime>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Prime>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Prime>

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
