package Bencher::Formatter::ScaleTime;

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use List::MoreUtils qw(minmax);
use POSIX ();

use Role::Tiny::With;
with 'Bencher::Role::ResultMunger';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-29'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.062'; # VERSION

sub munge_result {
    my ($self, $envres) = @_;

    return unless @{$envres->[2]};

    # pick an appropriate time unit & format the time
    my ($min, $max) = minmax(map {$_->{time}} @{$envres->[2]});

    # workaround for bug RT#113117 (max sometimes undef)
    $max //= $min;

    my $unit = "";
    my $factor = 1;
    if ($max <= 1.5e-6) {
        $unit = "ns";
        $factor = 1e9;
    } elsif ($max <= 1.5e-3) {
        $unit = "\x{03bc}s"; # XXX enable utf
        $factor = 1e6;
    } elsif ($max <= 1.5) {
        $unit = "ms";
        $factor = 1e3;
    }

    $envres->[3]{'func.time_factor'} = $factor;

    if ($unit) {
        for my $rit (@{$envres->[2]}) {
            $rit->{time} *= $factor;
            if (exists $rit->{mod_overhead_time}) {
                $rit->{mod_overhead_time} *= $factor;
            }
        }

        $envres->[3]{'table.field_units'} //= [];
        my $fus = $envres->[3]{'table.field_units'};

        my $i = -1;
        for my $f (@{$envres->[3]{'table.fields'}}) {
            $i++;
            if ($f =~ /\A(time|mod_overhead_time)\z/) {
                $fus->[$i] = $unit;
            }
        }
    }
}

1;
# ABSTRACT: Scale time to make it convenient

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::ScaleTime - Scale time to make it convenient

=head1 VERSION

This document describes version 1.062 of Bencher::Formatter::ScaleTime (from Perl distribution Bencher-Backend), released on 2022-11-29.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
