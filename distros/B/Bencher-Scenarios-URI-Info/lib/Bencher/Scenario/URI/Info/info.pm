package Bencher::Scenario::URI::Info::info;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-08'; # DATE
our $DIST = 'Bencher-Scenarios-URI-Info'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark info()',
    participants => [],
    datasets => [
        {name=>'google', args=>{url=>'https://www.google.com/search?client=firefox&q=foo+bar'}},
        {name=>'google maps', include_by_default=>0, args=>{url=>'https://maps.google.com/maps?q=driver+liu+hits+passenger+dalian&safe=strict&client=firefox-b-d&biw=1600&bih=741&dpr=1&um=1&ie=UTF-8&sa=X&ved=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'}},
    ],
};

my $ui;
{
    require URI::Info;
    local $ENV{URI_INFO_PLUGINS};
    $ui = URI::Info->new;
}

push @{$scenario->{participants}}, {
    name => 'URI::Info (all '.(scalar @{ $ui->{include_plugins} }).' plugins)',
    module => 'URI::Info',
    code_template => 'state $ui = URI::Info->new(); $ui->info(<url>)',
};

push @{$scenario->{participants}}, {
    name => 'URI::Info (google plugin only)',
    module => 'URI::Info',
    code_template => 'state $ui = URI::Info->new(include_plugins=>["SearchQuery::google"]); $ui->info(<url>)',
};

push @{$scenario->{participants}}, {
    name => 'URI::ParseSearchString->se_term',
    module => 'URI::ParseSearchString',
    code_template => 'state $us = URI::ParseSearchString->new; $us->se_term(<url>)',
};

push @{$scenario->{participants}}, {
    name => 'URI::ParseSearchString->se_term+findEngine',
    module => 'URI::ParseSearchString',
    result_is_list => 1,
    code_template => 'state $us = URI::ParseSearchString->new; ($us->se_term(<url>), $us->findEngine(<url>))',
};

1;
# ABSTRACT: Benchmark info()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::URI::Info::info - Benchmark info()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::URI::Info::info (from Perl distribution Bencher-Scenarios-URI-Info), released on 2021-10-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m URI::Info::info

To run module startup overhead benchmark:

 % bencher --module-startup -m URI::Info::info

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<URI::Info> 0.001

L<URI::ParseSearchString> 3.51

=head1 BENCHMARK PARTICIPANTS

=over

=item * URI::Info (all 3 plugins) (perl_code)

Code template:

 state $ui = URI::Info->new(); $ui->info(<url>)



=item * URI::Info (google plugin only) (perl_code)

Code template:

 state $ui = URI::Info->new(include_plugins=>["SearchQuery::google"]); $ui->info(<url>)



=item * URI::ParseSearchString->se_term (perl_code)

Code template:

 state $us = URI::ParseSearchString->new; $us->se_term(<url>)



=item * URI::ParseSearchString->se_term+findEngine (perl_code)

Code template:

 state $us = URI::ParseSearchString->new; ($us->se_term(<url>), $us->findEngine(<url>))



=back

=head1 BENCHMARK DATASETS

=over

=item * google

=item * google maps (not included by default)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m URI::Info::info >>):

 #table1#
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | URI::Info (all 3 plugins)                  |     24307 |    41.141 |                 0.00% |               146.96% |   6e-11 |      20 |
 | URI::Info (google plugin only)             |     24500 |    40.8   |                 0.72% |               145.20% | 3.7e-08 |      24 |
 | URI::ParseSearchString->se_term+findEngine |     36200 |    27.6   |                48.87% |                65.89% | 1.3e-08 |      20 |
 | URI::ParseSearchString->se_term            |     60000 |    17     |               146.96% |                 0.00% | 2.7e-08 |      20 |
 +--------------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                 Rate  URI::Info (all 3 plugins)  URI::Info (google plugin only)  URI::ParseSearchString->se_term+findEngine  URI::ParseSearchString->se_term 
  URI::Info (all 3 plugins)                   24307/s                         --                              0%                                        -32%                             -58% 
  URI::Info (google plugin only)              24500/s                         0%                              --                                        -32%                             -58% 
  URI::ParseSearchString->se_term+findEngine  36200/s                        49%                             47%                                          --                             -38% 
  URI::ParseSearchString->se_term             60000/s                       142%                            140%                                         62%                               -- 
 
 Legends:
   URI::Info (all 3 plugins): participant=URI::Info (all 3 plugins)
   URI::Info (google plugin only): participant=URI::Info (google plugin only)
   URI::ParseSearchString->se_term: participant=URI::ParseSearchString->se_term
   URI::ParseSearchString->se_term+findEngine: participant=URI::ParseSearchString->se_term+findEngine

=for html <img src="data:image/png;base64,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" />


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-URI-Info>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-URI-Info>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-URI-Info>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
