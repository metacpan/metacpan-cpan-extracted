#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;

use My::Test::Utils;
use My::Test::T1;

my $table = My::Test::Utils->test_table;
My::Test::T1->sqlt_deploy_hook($table);
my %idx = map { $_->name => [$_->fields] } $table->get_indices;

cmp_deeply([keys %idx], bag(qw(ix idx2 idx3)));
cmp_deeply($idx{idx2}, ['a', 'c']);
cmp_deeply($idx{idx3}, ['d', 'a']);

done_testing();
