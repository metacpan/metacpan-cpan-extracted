# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic;

# ----------------------------------------------------------------------

my $i = 0

=pod

++$i

=cut

is $i, 0

# ----------------------------------------------------------------------

my $j = 0

=head1

foreach my $foo 1..100:
    ++$j

=cut

is $j, 0
