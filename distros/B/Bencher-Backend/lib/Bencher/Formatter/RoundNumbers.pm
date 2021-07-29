package Bencher::Formatter::RoundNumbers;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.057'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Math::ScientificNotation::Util qw(sci2dec);
use Scalar::Util qw(looks_like_number);

use Role::Tiny::With;
with 'Bencher::Role::ResultMunger';

sub munge_result {
    my ($self, $envres) = @_;

    my $ff = $envres->[3]{'table.fields'};

    my $code_fmt = sub {
        my ($num_significant_digits, $num, $scientific_notation) = @_;
        $scientific_notation //= $self->{scientific_notation};
        $num = sprintf("%.${num_significant_digits}g", $num);
        $num = sci2dec($num) unless $scientific_notation;
        $num;
    };

    for my $rit (@{$envres->[2]}) {
        my $num_significant_digits = do {
            if (!defined($rit->{errors}) || $rit->{errors} == 0) {
                6;
            } elsif (exists $rit->{time}) {
                sprintf("%d", log( abs($rit->{time}) /
                                       ($envres->[3]{'func.time_factor'} // 1) /
                                       $rit->{errors} )/log(10));
            } else {
                die "BUG: no 'time' defined?";
            }
        };
        $rit->{time} = $code_fmt->($num_significant_digits, $rit->{time});
        if (exists $rit->{rate}) {
            $rit->{rate} = $code_fmt->($num_significant_digits, $rit->{rate});
        }
        $rit->{errors} = $code_fmt->(2, $rit->{errors}, 1)
            if defined $rit->{errors};

        # XXX this formatter shouldn't be aware directly of mod_overhead_time
        if (exists $rit->{mod_overhead_time}) {
            $rit->{mod_overhead_time} = $code_fmt->(
                $num_significant_digits, $rit->{mod_overhead_time});
        }
        # XXX this formatter shouldn't be aware directly of vs_slowest
        if (exists $rit->{vs_slowest}) {
            $rit->{vs_slowest} = $code_fmt->(
                $num_significant_digits, $rit->{vs_slowest});
        }

        # we don't need to round *_size fields to n significant digits because
        # they are not time measurement, but we do want to round it when it has
        # been divided when converting unit to kB, MB, etc.
        for my $col (keys %$rit) {
            if ($col =~ /^(result|proc_\w+|proc|arg_\w+)_size$/ && $rit->{$col} != int($rit->{$col})) {
                $rit->{$col} = $code_fmt->(
                    $num_significant_digits, $rit->{$col});
            }
        }
    }
}

1;
# ABSTRACT: Round numbers (rate, time) to certain significant digits according to errors

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::RoundNumbers - Round numbers (rate, time) to certain significant digits according to errors

=head1 VERSION

This document describes version 1.057 of Bencher::Formatter::RoundNumbers (from Perl distribution Bencher-Backend), released on 2021-07-23.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
