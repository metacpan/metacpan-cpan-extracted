package Benchmark::Perl::Formance::Plugin::PerlStone2015::05regex;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - perl 05 - regex
$Benchmark::Perl::Formance::Plugin::PerlStone2015::05regex::VERSION = '0.002';
use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';

sub fixedstr
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 300_000 : 1_000_000;
        my $count  = $options->{fastmode} ?       1 : 3;

        my $t = timeit $count, sub {
                my $s;
                $s = "a" x 10_000 . "wxyz";
                $s =~ /wxyz/ for 1..$goal;
        };

        return {
                Benchmark  => $t,
                goal       => $goal,
                count      => $count,
               };
}

sub main
{
        my ($options) = @_;

        my $results;
        eval {
                $results = {
                            fixedstr   => fixedstr($options),
                           };
        };

        if ($@) {
                warn $@ if $options->{verbose};
                $results = { failed => $@ };
        }

        return $results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::05regex - benchmark - perl 05 - regex

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
