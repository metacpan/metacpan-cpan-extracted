#!/usr/bin/perl

=head1 NAME

rt_72808.t - Acme::24 unit test suite

=head1 DESCRIPTION

Check that RT#72808 is actually fixed.
Should return 24 facts, not 25.

=cut

use strict;
use warnings;
use Acme::24;
use Test::More tests => 1;
use Data::Dumper;

my $facts = Acme::24->random_jackbauer_facts();

ok(
    $facts
    && (ref $facts eq 'ARRAY')
    && @{ $facts } == 24,
    'Got 24 facts, not 25, dammit!'
);

#diag(Data::Dumper::Dumper($facts));
#diag("Got " . scalar(@{$facts}) . " facts");

