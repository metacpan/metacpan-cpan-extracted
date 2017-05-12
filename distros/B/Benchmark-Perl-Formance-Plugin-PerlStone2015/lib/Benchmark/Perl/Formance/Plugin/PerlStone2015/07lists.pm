package Benchmark::Perl::Formance::Plugin::PerlStone2015::07lists;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - perl 07 - lists
$Benchmark::Perl::Formance::Plugin::PerlStone2015::07lists::VERSION = '0.002';
use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';
use Data::Dumper;

sub _unshift
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 1_000_000 : 1_000_000;
        my $count  = $options->{fastmode} ? 5 : 100;
        my $s      = "somestring" x 50;

        my $t = timeit $count, sub {
                my @stuff = ();
                unshift @stuff, $s for 1..$goal;
        };

        return {
                Benchmark  => $t,
                goal       => $goal,
                count      => $count,
               };
}

sub _push
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 1_000_000 : 1_000_000;
        my $count  = $options->{fastmode} ? 5 : 100;
        my $s      = "somestring" x 50;

        my $t = timeit $count, sub {
                my @stuff = ();
                push @stuff, $s for 1..$goal;
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
                            unshift    => _unshift($options),
                            push       => _push($options),
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

Benchmark::Perl::Formance::Plugin::PerlStone2015::07lists - benchmark - perl 07 - lists

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
