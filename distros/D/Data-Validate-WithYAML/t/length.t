#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Validate::WithYAML;

my $sub = Data::Validate::WithYAML->can('_length');

is $sub->( 'string', '13' ), '';
is $sub->( 'string', '13,20' ), '0';
is $sub->( 'string', ',20' ), 1;
is $sub->( 'string', '13,' ), '0';
is $sub->( 'string', '4,' ), 1;
is $sub->( 'string', '1,3' ), '0';
is $sub->( 'string', '1,8' ), 1;

done_testing();
