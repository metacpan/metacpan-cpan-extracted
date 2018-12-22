package Bencher::Scenario::TimeHiRes::usleep_accuracy;

our $DATE = '2018-12-21'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Demonstrate inaccuracy of doing lots of small usleep',
    modules => {
    },
    participants => [
        {
            name => '1e5 x1',
            fcall_template => 'Time::HiRes::usleep(1e5)',
        },
        {
            name => '1e4 x10',
            fcall_template => 'Time::HiRes::usleep(1e4) for 1..10',
        },
        {
            name => '1e3 x100',
            fcall_template => 'Time::HiRes::usleep(1e3) for 1..100',
        },
        {
            name => '1e2 x1000',
            fcall_template => 'Time::HiRes::usleep(1e2) for 1..1000',
        },
        {
            name => '1e1 x10000',
            fcall_template => 'Time::HiRes::usleep(1e1) for 1..10000',
        },
        {
            name => '1e0 x100000',
            fcall_template => 'Time::HiRes::usleep(1e0) for 1..100_000',
        },
    ],
    precision => 6,
};

1;
# ABSTRACT: Demonstrate inaccuracy of doing lots of small usleep

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TimeHiRes::usleep_accuracy - Demonstrate inaccuracy of doing lots of small usleep

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::TimeHiRes::usleep_accuracy (from Perl distribution Bencher-Scenarios-TimeHiRes), released on 2018-12-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TimeHiRes::usleep_accuracy

To run module startup overhead benchmark:

 % bencher --module-startup -m TimeHiRes::usleep_accuracy

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Basically the same as L<Bencher::Scenario::TimeHiRes::sleep_accuracy>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Time::HiRes>

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1e5 x1 (perl_code)

Function call template:

 Time::HiRes::usleep(1e5)



=item * 1e4 x10 (perl_code)

Function call template:

 Time::HiRes::usleep(1e4) for 1..10



=item * 1e3 x100 (perl_code)

Function call template:

 Time::HiRes::usleep(1e3) for 1..100



=item * 1e2 x1000 (perl_code)

Function call template:

 Time::HiRes::usleep(1e2) for 1..1000



=item * 1e1 x10000 (perl_code)

Function call template:

 Time::HiRes::usleep(1e1) for 1..10000



=item * 1e0 x100000 (perl_code)

Function call template:

 Time::HiRes::usleep(1e0) for 1..100_000



=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TimeHiRes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TimeHiRes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TimeHiRes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
