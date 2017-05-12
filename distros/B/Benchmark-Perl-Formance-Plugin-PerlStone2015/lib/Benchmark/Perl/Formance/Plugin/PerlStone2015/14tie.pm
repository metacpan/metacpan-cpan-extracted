package Benchmark::Perl::Formance::Plugin::PerlStone2015::14tie;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - perl 14 - tie
$Benchmark::Perl::Formance::Plugin::PerlStone2015::14tie::VERSION = '0.002';
use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';

sub main
{
        my ($options) = @_;

        my $results;
        eval {
                $results = {
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

Benchmark::Perl::Formance::Plugin::PerlStone2015::14tie - benchmark - perl 14 - tie

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
