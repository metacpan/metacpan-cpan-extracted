package Bencher::Scenario::Interpreters::Startup;

use strict;
use warnings;

use File::Which qw(which);
use Interpreter::Info;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-07'; # DATE
our $DIST = 'Bencher-Scenario-Interpreters-Startup'; # DIST
our $VERSION = '0.041'; # VERSION

my @participants;

PERL: {
    my $path = which "perl";
    unless (defined $path) {
        warn "perl not available, skipped";
        last;
    }
    my $res = Interpreter::Info::get_perl_info(path=>$path);
    die "Can't get perl info: $res->[0] - $res->[1]" unless $res->[0] == 200;
    push @participants, {
        name => 'perl -e',
        summary => "perl (version $res->[2]{version})",
        cmdline=>[qw/perl -e1/],
    };
    push @participants, {
        name => 'perl -E',
        summary => "perl (version $res->[2]{version})",
        cmdline=>[qw/perl -E1/],
    };
}

PYTHON: {
    for my $which (qw/python3 python2/) {
        my $path = which $which;
        unless (defined $path) {
            warn "$which not available, skipped";
        last;
        }
        my $res = Interpreter::Info::get_python_info(path=>$path);
        die "Can't get python info: $res->[0] - $res->[1]" unless $res->[0] == 200;
        push @participants, {
            name => $which,
            summary => "$which (version $res->[2]{version})",
            cmdline=>[$which, '-c1'],
        };
        push @participants, {
            name => "$which -S",
            summary => "$which (version $res->[2]{version})",
            cmdline=>[$which, '-S', '-c1'],
        };
        push @participants, {
            name => "$which -S+exit",
            summary => "$which (version $res->[2]{version})",
            cmdline=>[$which, '-S', '-c', 'from os import _exit; _exit(0)'],
        };
    } # which
}

BASH: {
    my $path = which "bash";
    unless (defined $path) {
        warn "bash not available, skipped";
        last;
    }
    my $res = Interpreter::Info::get_bash_info(path=>$path);
    die "Can't get bash info: $res->[0] - $res->[1]" unless $res->[0] == 200;
    push @participants, {
        name => 'bash',
        summary => "bash (version $res->[2]{version})",
        cmdline=>['bash', '--norc', '-c', 'true'],
    };
}

RUBY: {
    my $path = which "ruby";
    unless (defined $path) {
        warn "ruby not available, skipped";
        last;
    }
    my $res = Interpreter::Info::get_ruby_info(path=>$path);
    die "Can't get ruby info: $res->[0] - $res->[1]" unless $res->[0] == 200;
    push @participants, {
        name => 'ruby',
        summary => "ruby (version $res->[2]{version})",
        cmdline=>['ruby', '-e1'],
    };
}

NODEJS: {
    for my $which (qw/nodejs node/) {
        my $path = which $which;
        unless (defined $path) {
            warn "nodejs not available, skipped";
            last;
        }
        my $res = Interpreter::Info::get_nodejs_info(path=>$path);
        die "Can't get nodejs info: $res->[0] - $res->[1]" unless $res->[0] == 200;
        push @participants, {
            name => 'nodejs',
            summary => "nodejs (version $res->[2]{version})",
            cmdline=>[$which, '-e', 1],
        };
        last;
    }
}

RAKUDO: {
    my $path = which "rakudo";
    unless (defined $path) {
        warn "rakudo not available, skipped";
        last;
    }
    my $res = Interpreter::Info::get_rakudo_info(path=>$path);
    die "Can't get rakudo info: $res->[0] - $res->[1]" unless $res->[0] == 200;
    push @participants, {
        name => 'rakudo',
        summary => "rakudo (version $res->[2]{version})",
        cmdline=>['rakudo', '-e;'],
    };
}

die "Can't find any participants" unless @participants;

our $scenario = {
    summary => 'Benchmark startup time of various interpreters',
    participants => \@participants,
};

1;
# ABSTRACT: Benchmark startup time of various interpreters

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Interpreters::Startup - Benchmark startup time of various interpreters

=head1 VERSION

This document describes version 0.041 of Bencher::Scenario::Interpreters::Startup (from Perl distribution Bencher-Scenario-Interpreters-Startup), released on 2023-12-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Interpreters::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl -e (command)

perl (version 5.38.2).

Command line:

 perl -e1



=item * perl -E (command)

perl (version 5.38.2).

Command line:

 perl -E1



=item * python3 (command)

python3 (version 3.8.10).

Command line:

 python3 -c1



=item * python3 -S (command)

python3 (version 3.8.10).

Command line:

 python3 -S -c1



=item * python3 -S+exit (command)

python3 (version 3.8.10).

Command line:

 python3 -S -c from os import _exit; _exit(0)



=item * python2 (command)

python2 (version 2.7.18).

Command line:

 python2 -c1



=item * python2 -S (command)

python2 (version 2.7.18).

Command line:

 python2 -S -c1



=item * python2 -S+exit (command)

python2 (version 2.7.18).

Command line:

 python2 -S -c from os import _exit; _exit(0)



=item * bash (command)

bash (version 5.0.17(1)-release).

Command line:

 bash --norc -c true



=item * ruby (command)

ruby (version 2.7.0p0).

Command line:

 ruby -e1



=item * nodejs (command)

nodejs (version 10.19.0).

Command line:

 nodejs -e 1



=item * rakudo (command)

rakudo (version 2023.11).

Command line:

 rakudo -e;



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Interpreters::Startup

Result formatted as table:

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | nodejs          |       2.3 |    430    |                 0.00% |              7178.18% |   0.0013  |      20 |
 | rakudo          |       5.7 |    170    |               146.83% |              2848.72% |   0.00064 |      20 |
 | ruby            |      17   |     57    |               648.52% |               872.34% | 6.1e-05   |      20 |
 | python3         |      42.9 |     23.3  |              1747.35% |               293.98% | 1.9e-05   |      20 |
 | python3 -S+exit |      64   |     16    |              2666.32% |               163.10% | 7.9e-05   |      31 |
 | python2         |      75.1 |     13.3  |              3129.31% |               125.38% | 9.2e-06   |      20 |
 | python3 -S      |      78.1 |     12.8  |              3259.06% |               116.67% |   7e-06   |      20 |
 | python2 -S+exit |      97.6 |     10.2  |              4098.98% |                73.33% | 5.5e-06   |      20 |
 | python2 -S      |     124   |      8.06 |              5236.94% |                36.37% |   6e-06   |      20 |
 | perl -E         |     140   |      7    |              6032.49% |                18.68% | 9.6e-06   |      20 |
 | bash            |     160   |      6.1  |              6985.92% |                 2.71% | 4.5e-05   |      20 |
 | perl -e         |     169   |      5.91 |              7178.18% |                 0.00% | 4.3e-06   |      20 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                     Rate  nodejs  rakudo  ruby  python3  python3 -S+exit  python2  python3 -S  python2 -S+exit  python2 -S  perl -E  bash  perl -e 
  nodejs            2.3/s      --    -60%  -86%     -94%             -96%     -96%        -97%             -97%        -98%     -98%  -98%     -98% 
  rakudo            5.7/s    152%      --  -66%     -86%             -90%     -92%        -92%             -94%        -95%     -95%  -96%     -96% 
  ruby               17/s    654%    198%    --     -59%             -71%     -76%        -77%             -82%        -85%     -87%  -89%     -89% 
  python3          42.9/s   1745%    629%  144%       --             -31%     -42%        -45%             -56%        -65%     -69%  -73%     -74% 
  python3 -S+exit    64/s   2587%    962%  256%      45%               --     -16%        -19%             -36%        -49%     -56%  -61%     -63% 
  python2          75.1/s   3133%   1178%  328%      75%              20%       --         -3%             -23%        -39%     -47%  -54%     -55% 
  python3 -S       78.1/s   3259%   1228%  345%      82%              25%       3%          --             -20%        -37%     -45%  -52%     -53% 
  python2 -S+exit  97.6/s   4115%   1566%  458%     128%              56%      30%         25%               --        -20%     -31%  -40%     -42% 
  python2 -S        124/s   5234%   2009%  607%     189%              98%      65%         58%              26%          --     -13%  -24%     -26% 
  perl -E           140/s   6042%   2328%  714%     232%             128%      90%         82%              45%         15%       --  -12%     -15% 
  bash              160/s   6949%   2686%  834%     281%             162%     118%        109%              67%         32%      14%    --      -3% 
  perl -e           169/s   7175%   2776%  864%     294%             170%     125%        116%              72%         36%      18%    3%       -- 
 
 Legends:
   bash: participant=bash
   nodejs: participant=nodejs
   perl -E: participant=perl -E
   perl -e: participant=perl -e
   python2: participant=python2
   python2 -S: participant=python2 -S
   python2 -S+exit: participant=python2 -S+exit
   python3: participant=python3
   python3 -S: participant=python3 -S
   python3 -S+exit: participant=python3 -S+exit
   rakudo: participant=rakudo
   ruby: participant=ruby

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

C<perl> has always been strong in startup overhead; it only loses to bash in
this benchmark.

C<nodejs> has really terrible startup overhead (rakudo even beats it), which is
a pity because it's utilized a lot to power CLI's.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Interpreters-Startup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Interpreters-Startup>.

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

This software is copyright (c) 2023, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Interpreters-Startup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
