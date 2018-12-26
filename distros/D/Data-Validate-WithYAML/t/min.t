#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Validate::WithYAML;

my $sub = Data::Validate::WithYAML->can('_min');

is $sub->( 'string', '13' ), undef;
is $sub->( 'string', '-1' ), undef;
is $sub->( -1, '20' ), '';
is $sub->( 5, '20' ), '';
is $sub->( 5.319, '20' ), '';
is $sub->( 29, '20' ), 1;
is $sub->( 29.313, '20' ), 1;

done_testing();
