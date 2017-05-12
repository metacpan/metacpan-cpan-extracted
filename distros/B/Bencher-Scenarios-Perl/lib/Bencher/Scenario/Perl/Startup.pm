package Bencher::Scenario::Perl::Startup;

our $DATE = '2016-03-15'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::perlbrew;
use File::Which;

my $participants = [];

my $pb = App::perlbrew->new;
for my $perl ($pb->installed_perls) {
    push @$participants, {
        name => "$perl->{name} -e1",
        cmdline => [$perl->{executable}, "-e1"],
    };
    if (version->parse($perl->{version}) >= version->parse("5.10.0")) {
        push @$participants, {
            name => "$perl->{name} -E1",
            cmdline => [$perl->{executable}, "-E1"],
        };
    }
}

our $scenario = {
    summary => 'Benchmark startup time of perls',
    default_precision => 0.005,
    participants => $participants,
};

1;
# ABSTRACT: Benchmark startup time of perls

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::Startup - Benchmark startup time of perls

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::Perl::Startup (from Perl distribution Bencher-Scenarios-Perl), released on 2016-03-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl-5.6.2 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.6.2/bin/perl -e1



=item * perl-5.8.9 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.8.9/bin/perl -e1



=item * perl-5.10.1 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -e1



=item * perl-5.10.1 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -E1



=item * perl-5.12.5 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -e1



=item * perl-5.12.5 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -E1



=item * perl-5.14.4 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -e1



=item * perl-5.14.4 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -E1



=item * perl-5.16.3 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -e1



=item * perl-5.16.3 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -E1



=item * perl-5.18.4 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -e1



=item * perl-5.18.4 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -E1



=item * perl-5.20.3 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -e1



=item * perl-5.20.3 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -E1



=item * perl-5.22.0 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.0/bin/perl -e1



=item * perl-5.22.0 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.0/bin/perl -E1



=item * perl-5.22.1 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.1/bin/perl -e1



=item * perl-5.22.1 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.1/bin/perl -E1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m Perl::Startup >>):

 +-----------------+-----------+-----------+------------+---------+---------+
 | participant     | rate (/s) | time (ms) | vs_slowest | errors  | samples |
 +-----------------+-----------+-----------+------------+---------+---------+
 | perl-5.22.0 -E1 | 1.8e+02   | 5.5       | 1          | 2.6e-05 | 59      |
 | perl-5.20.3 -E1 | 1.9e+02   | 5.4       | 1          | 2.7e-05 | 24      |
 | perl-5.22.1 -E1 | 1.9e+02   | 5.4       | 1          | 2.4e-05 | 34      |
 | perl-5.16.3 -E1 | 1.9e+02   | 5.2       | 1.1        | 2.4e-05 | 20      |
 | perl-5.18.4 -E1 | 1.9e+02   | 5.2       | 1          | 1.9e-05 | 21      |
 | perl-5.10.1 -E1 | 2e+02     | 5         | 1.1        | 2.3e-05 | 62      |
 | perl-5.12.5 -E1 | 2e+02     | 4.9       | 1.1        | 2e-05   | 21      |
 | perl-5.14.4 -E1 | 2e+02     | 4.9       | 1.1        | 1.6e-05 | 21      |
 | perl-5.22.0 -e1 | 2.1e+02   | 4.7       | 1.2        | 2.1e-05 | 58      |
 | perl-5.20.3 -e1 | 2.2e+02   | 4.5       | 1.2        | 2.1e-05 | 74      |
 | perl-5.14.4 -e1 | 2.3e+02   | 4.4       | 1.3        | 1.9e-05 | 28      |
 | perl-5.16.3 -e1 | 2.3e+02   | 4.4       | 1.2        | 1.5e-05 | 20      |
 | perl-5.22.1 -e1 | 2.3e+02   | 4.4       | 1.3        | 1.3e-05 | 20      |
 | perl-5.10.1 -e1 | 2.4e+02   | 4.3       | 1.3        | 2e-05   | 20      |
 | perl-5.12.5 -e1 | 2.3e+02   | 4.3       | 1.3        | 1.9e-05 | 20      |
 | perl-5.18.4 -e1 | 2.3e+02   | 4.3       | 1.3        | 1.6e-05 | 20      |
 | perl-5.8.9 -e1  | 2.4e+02   | 4.2       | 1.3        | 1.4e-05 | 20      |
 | perl-5.6.2 -e1  | 2.4e+02   | 4.1       | 1.3        | 2e-05   | 92      |
 +-----------------+-----------+-----------+------------+---------+---------+

=head1 DESCRIPTION

Conclusion: in general newer versions of perl has larger startup overhead than
previous ones. If startup overhead is important to you, use C<-e> instead of
C<-E> unless necessary.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::Interpreters>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
