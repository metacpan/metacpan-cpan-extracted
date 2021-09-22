package Benchmark::Perl::Formance::Plugin::Incubator;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - Incubator - everchanging benchmark experiments

use strict;
use warnings;

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';

sub incubator
{
        my ($options) = @_;

        my $count = 1;

        my $t = timeit $count, sub { sleep 2 };
        return {
                Benchmark => $t,
                goal      => $count,
               };
}

sub main
{
        my ($options) = @_;

        return {
                incubator => incubator ($options),
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Incubator - benchmark plugin - Incubator - everchanging benchmark experiments

=head1 ABOUT

This is a B<free style> plugin where I collect ideas. Although it
might contain interesting code you should never rely on this plugin as
it will continuously change.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
