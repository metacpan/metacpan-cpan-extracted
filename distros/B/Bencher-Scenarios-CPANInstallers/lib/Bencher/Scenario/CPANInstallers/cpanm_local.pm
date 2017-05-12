package Bencher::Scenario::CPANInstallers::cpanm_local;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::lcpan::Call qw(check_lcpan);
use File::Temp qw(tempdir);
use URI::Escape;

our $scenario = {
    summary => 'Benchmark installing modules from a local mirror using cpanm',
    description => <<'_',

This benchmark runs `cpanm Moose` with `-n` (no testing), `--mirror
LOCAL_CPAN_MIRROR_PATH --mirror-only` (no consulting the network), and
`--local-lib-contained TEMP_DIR`. This measures more or less "raw" cpanm
performance.

To run this benchmark, you need a fairly recent local CPAN mirror
(downloaded/maintained using <pm:App::lcpan>).

_
    modules => {
        'App::cpanminus' => {},
    },

    participants => [
        {
            name             => "cpanm",
            cmdline_template => ["cpanm", "--mirror", '<mirror_url>', "--mirror-only", "-L", '<tempdir>', "-n", '<module>'],
        },
    ],

    runner => "Benchmark::Dumb::SimpleTime",

    precision => 1,

    test => 0,

    before_list_datasets => sub {
        my %args = @_;

        my $scenario = $args{scenario};

        # add dataset
        {
            my $check_res = check_lcpan();
            die "$check_res->[1]\n" unless $check_res->[0] == 200;
            my $mirror_path = $check_res->[2]{cpan};

            #my $mirror_url = "file:" . uri_escape($mirror_path);
            my $mirror_url = "file:" . $mirror_path; # cpanm doesn't accept encoded URL?

            my $tempdir = tempdir(CLEANUP => 1);

            push @{ $scenario->{datasets} }, {
                name => 'default',
                seq => 0,
                args => {mirror_url=>$mirror_url, tempdir=>$tempdir, module=>"Moose"},
            };
        }
    },

    datasets => undef,
};

1;
# ABSTRACT: Benchmark installing modules from a local mirror using cpanm

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CPANInstallers::cpanm_local - Benchmark installing modules from a local mirror using cpanm

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::CPANInstallers::cpanm_local (from Perl distribution Bencher-Scenarios-CPANInstallers), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CPANInstallers::cpanm_local

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

This benchmark runs C<cpanm Moose> with C<-n> (no testing), C<--mirror
LOCAL_CPAN_MIRROR_PATH --mirror-only> (no consulting the network), and
C<--local-lib-contained TEMP_DIR>. This measures more or less "raw" cpanm
performance.

To run this benchmark, you need a fairly recent local CPAN mirror
(downloaded/maintained using L<App::lcpan>).


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::cpanminus>

=head1 BENCHMARK PARTICIPANTS

=over

=item * cpanm (command)

Command line:

 #TEMPLATE: cpanm --mirror <mirror_url> --mirror-only -L <tempdir> -n <module>



=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CPANInstallers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CPANInstallers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CPANInstallers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
