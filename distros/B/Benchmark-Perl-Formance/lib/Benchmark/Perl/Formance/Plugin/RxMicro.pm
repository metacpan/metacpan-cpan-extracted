package Benchmark::Perl::Formance::Plugin::RxMicro;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - Rx - Stress regular expressions

# Regexes

use strict;
use warnings;

our $VERSION = "0.003";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
# The code in here has compile-time and run-time effects!   #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';
use Data::Dumper;

our $goal;
our $count;

sub rxmicro
{
        my ($options) = @_;

        my %results = ();

        # ----------------------------------------------------

        {
                # how quickly a pre-compiled regex is accessed:

                my $subtest = "precompile-access";
                my $r = qr/\d+/;
                my $t = timeit $count, sub { "1234" =~ $r for 1..50000*$goal };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        {
                # how quickly run-time regexes are compiled

                my $subtest = "runtime-compile";
                my $r ='\d+';
                my $t = timeit $count, sub { "1234" =~ $r for 1..100000*$goal };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        {
                # run-time regexes are compiled but defeating the caching

                my $subtest = "runtime-compile-nocache";
                my $r ='\d+';
                my $t = timeit $count, sub { "1234" =~ /$r$_/ for 1..10000*$goal };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        {
                # run-time code-blocks

                my $subtest = "code-runtime";
                my $counter;
                my $code = '(?{$counter++})';
                use re 'eval';

                my $mygoal = $options->{fastmode} ? 10_000 : 20_000*$goal;

                my $t = timeit $count, sub { $counter = 0; "1234" =~ /\d+$code/ for 1..$mygoal };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                      counter   => $counter,
                                     };
        }

        # ----------------------------------------------------

        {
                # literal code-blocks

                my $cnt;
                my $subtest = "code-literal";
                my $t = timeit $count, sub { "1234" =~ /\d+(?{$cnt++})/ for 1..40000*$goal };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        return \%results;
}

sub main
{
        my ($options) = @_;

        $goal   = $options->{fastmode} ? 20 : 29;
        $count  = $options->{fastmode} ? 1 : 5;

        return rxmicro($options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::RxMicro - benchmark plugin - Rx - Stress regular expressions

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
