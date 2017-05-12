package App::Benchmark;
use strict;
use warnings;
use Test::More;
use Benchmark qw(cmpthese timethese :hireswallclock);
use Capture::Tiny qw(capture);
use Exporter qw(import);
our $VERSION = '2.00';
our @EXPORT  = qw(benchmark_diag);

sub benchmark_diag {
    my ($iterations, $benchmark_hash) = @_;
    my $stdout = capture {
        cmpthese(timethese($iterations, $benchmark_hash));
    };
    diag $stdout;
    plan tests => 1;
    pass('benchmark');
}
1;
__END__

=head1 NAME

App::Benchmark - Output your benchmarks as test diagnostics

=head1 SYNOPSIS

    # This is t/benchmark.t:

    use App::Benchmark;

    benchmark_diag(2_000_000, {
        sqrt => sub { sqrt(2) },
        log  => sub { log(2) },
    });

=head1 DESCRIPTION

This module makes it easy to run your benchmarks in a distribution's test
suite. This way you just have to look at the CPAN testers reports to see your
benchmarks being run on many different platforms using many different versions
of perl.

Ricardo Signes came up with the idea.

=head1 FUNCTIONS

=head2 benchmark_diag

Takes a number of iterations and a benchmark definition hash, just like
C<timethese()> from the L<Benchmark> module. Runs the benchmarks and reports
them, each line prefixed by a hash sign so it doesn't mess up the TAP output.
Also, a dummy test is being generated to keep the testing framework happy.

This function is exported automatically.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution unless explicitly noted otherwise.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

