package Benchmark::Dumb::SimpleTime;

use strict;
use warnings;
use Time::HiRes qw(time);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-29'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.062'; # VERSION

sub _timethese_guts {
    my ($count, $subs, $silent) = @_;

    my $res = {};
    for my $name (keys %$subs) {
        my $sub = $subs->{$name};

        my $time_start = time();
        $sub->() for 1..$count;
        my $time_end   = time();

        $res->{$name} = bless({
            name => $name,
            result => bless({
                num => ($time_end - $time_start)/$count,
                _dbr_nsamples => $count,
                errors => [undef],
            }, "Dumbbench::result"),
        }, "Benchmark::Dumb");
    }

    # we are always silent for now
    $res;
}

1;
# ABSTRACT: Benchmark::Dumb interface for simple time() based benchmarking

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Dumb::SimpleTime - Benchmark::Dumb interface for simple time() based benchmarking

=head1 VERSION

This document describes version 1.062 of Benchmark::Dumb::SimpleTime (from Perl distribution Bencher-Backend), released on 2022-11-29.

=head1 DESCRIPTION

Used internally by L<Bencher::Backend>.

This benchmarks code using simple C<time()> to measure time interval. No
outliers removal or any statistics methods are applied. Returns result similar
to what L<Benchmark::Dumb>'s C<_timethese_guts()> returns, with C<errors> set to
C<[undef]>. Might be usable if you don't care about any of the stuffs that
L<Dumbbench> cares about, and you want to benchmark code that runs at least one
or a few seconds with few iterations (1 to 5) , where Benchmark::Dumb will
complain that the "number of runs is very small".

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
