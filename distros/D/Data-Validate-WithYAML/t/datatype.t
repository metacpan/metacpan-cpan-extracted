#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Validate::WithYAML;

my $sub = Data::Validate::WithYAML->can('_datatype');

is $sub->( -1, 'positive_int' ), '';
is $sub->( 2, 'positive_int' ), 1;
is $sub->( 2.131, 'positive_int' ), undef;
is $sub->( 'string', 'positive_int' ), undef;
is $sub->( {}, 'positive_int' ), undef;
is $sub->( {}, 'int' ), undef;
is $sub->( -1, 'int' ), 1;

done_testing();
