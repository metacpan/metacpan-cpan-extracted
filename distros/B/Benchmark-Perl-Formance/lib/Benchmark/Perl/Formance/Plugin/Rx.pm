package Benchmark::Perl::Formance::Plugin::Rx;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - Rx - Stress regular expressions

# Regexes

use strict;
use warnings;

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';
use Data::Dumper;

our $goal;
our $count;
our $length;

sub regexes
{
        my ($options) = @_;

        # http://swtch.com/~rsc/regexp/regexp1.html

        my $before;
        my $after;
        my %results = ();

        {
                my $subtest = "pathological";

                my $n      = $goal;
                my $re     = ("a?" x $n) . ("a" x $n);
                my $string = "a" x $n;

                my $t = timeit $count, sub { $string =~ /$re/ };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        # { "abcdefg",	"abcdefg"	},
        # { "(a|b)*a",	"ababababab"	},
        # { "(a|b)*a",	"aaaaaaaaba"	},
        # { "(a|b)*a",	"aaaaaabac"	},
        # { "a(b|c)*d",	"abccbcccd"	},
        # { "a(b|c)*d",	"abccbcccde"	},
        # { "a(b|c)*d",	"abcccccccc"	},
        # { "a(b|c)*d",	"abcd"		},

        # ----------------------------------------------------

        {
                my $subtest = "fieldsplit1";

                my $re     = '(.*) (.*) (.*) (.*) (.*)';
                my $string = (("a" x $length) . " ") x 5;
                chop $string;

                my $t = timeit $count, sub { $string =~ /$re/ };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        # ----------------------------------------------------

        {
                my $subtest = "fieldsplit2";

                my $re     = '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)';
                my $string = ( ("a" x $length) . " " ) x 5;
                chop $string;

                my $t = timeit $count, sub { $string =~ /$re/ };
                $results{$subtest} = {
                                      Benchmark => $t,
                                      goal      => $goal,
                                      count     => $count,
                                     };
        }

        $results{fieldsplitratio} = sprintf(
                                            "%0.4f",
                                            $results{fieldsplit1}{Benchmark}[1] / $results{fieldsplit2}{Benchmark}[1]
                                           );

        # ----------------------------------------------------

        return \%results;
}

sub main
{
        my ($options) = @_;

        $goal   = $options->{fastmode} ? 20 : 29;
        $length = $options->{fastmode} ? 1_000_000 : 10_000_000;
        $count  = 5;

        return {
                regexes => regexes($options),
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Rx - benchmark plugin - Rx - Stress regular expressions

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
