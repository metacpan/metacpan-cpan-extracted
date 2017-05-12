#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test that we can use Data::SExpression and construct D::Sexp objects.

=cut

use Test::More tests => 3;

use_ok('Data::SExpression');

can_ok('Data::SExpression', 'new');

my $ds = Data::SExpression->new();

isa_ok($ds, "Data::SExpression", 'new returned a Data::SExpression');
