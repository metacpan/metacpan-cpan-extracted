package Bencher::Formatter::ScaleSize;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-10'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.053'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use List::MoreUtils qw(minmax);
use POSIX ();

use Role::Tiny::With;
with 'Bencher::Role::ResultMunger';

sub munge_result {
    my ($self, $envres) = @_;

    return unless @{$envres->[2]};

    my @cols = grep {/^(result|proc_\w+|proc|arg\_\w+)_size$/} keys %{ $envres->[2][0] };
    return unless @cols;

  COL:
    for my $col (@cols) {
        # pick an appropriate time unit & format the time
        my ($min, $max) = minmax(map {$_->{$col}} @{$envres->[2]});

        # workaround for bug RT#113117 (max sometimes undef)
        $max //= $min;

        my ($unit, $factor);
        if ($max >= 1.1*2**40) {
            $unit = "TB";
            $factor = 2**-40;
        } elsif ($max >= 1.1*2**30) {
            $unit = "GB";
            $factor = 2**-30;
        } elsif ($max >= 1.1*2**20) {
            $unit = "MB";
            $factor = 2**-20;
        } elsif ($max >= 1.1*2**10) {
            $unit = "kB";
            $factor = 2**-10;
        } else {
            $unit = "b";
            $factor = 1;
        }

        if ($unit) {
            for my $rit (@{$envres->[2]}) {
                $rit->{$col} *= $factor;
            }

            $envres->[3]{'table.field_units'} //= [];
            my $fus = $envres->[3]{'table.field_units'};

            my $i = -1;
            for my $f (@{$envres->[3]{'table.fields'}}) {
                $i++;
                if ($f eq $col) {
                    $fus->[$i] = $unit;
                    last;
                }
            }
        } # if unit
    } # for each column
}

1;
# ABSTRACT: Scale size fields to make it convenient

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::ScaleSize - Scale size fields to make it convenient

=head1 VERSION

This document describes version 1.053 of Bencher::Formatter::ScaleSize (from Perl distribution Bencher-Backend), released on 2021-04-10.

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
