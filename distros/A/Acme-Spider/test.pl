#!/usr/bin/perl

=head1 NAME

test.pl - test Acme::Spider;

=head1 DESCRIPTION

This does something useful, so it should have a better description.

=cut

use strict;
use warnings;

use Test::More tests => 5;

require_ok 'Acme::Spider';

is ref $INC[0], 'CODE', "Spider in \@INC";

eval { require Coy };
ok $@, "require Coy croaked, as expected";
eval { require Quantum::Superpositions };
ok $@, "require Quantum::Superpositions croaked, as expected";

require_ok 'Benchmark';
