package Bencher::Scenario::Test::Sleep;

our $DATE = '2016-10-09'; # DATE
our $VERSION = '0.001'; # VERSION

use Time::HiRes qw();

our $scenario = {
    summary => 'A test scenario, containing Time::HiRes::sleep() commands',
    participants => [
        {name => 'sleep(2.9)'  , code_template => 'Time::HiRes::sleep 2.9'},
        {name => 'sleep(1.1)'  , code_template => 'Time::HiRes::sleep 1.1'},
        {name => 'sleep(0.5)', code_template => 'Time::HiRes::sleep 0.5'},
    ],
    runner => 'Benchmark::Dumb::SimpleTime',
    precision => 1,
};

1;
# ABSTRACT: A test scenario, containing Time::HiRes::sleep() commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Test::Sleep - A test scenario, containing Time::HiRes::sleep() commands

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Test::Sleep (from Perl distribution Bencher-Scenario-Test-Sleep), released on 2016-10-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Test::Sleep

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * sleep(2.9) (perl_code)

Code template:

 Time::HiRes::sleep 2.9



=item * sleep(1.1) (perl_code)

Code template:

 Time::HiRes::sleep 1.1



=item * sleep(0.5) (perl_code)

Code template:

 Time::HiRes::sleep 0.5



=back

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Test-Sleep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Test-Sleep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Test-Sleep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
