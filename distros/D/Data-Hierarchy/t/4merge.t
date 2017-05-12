#!/usr/bin/perl
use Test::More tests => 3;
use strict;
use warnings;
BEGIN {
use_ok 'Data::Hierarchy';
}

my $t1 = Data::Hierarchy->new;
$t1->store('/foo',     { A => 1 });

my $t2 = Data::Hierarchy->new;
$t2->store('/foo',     { A => 3 });
$t2->store('/foo/bar', { A => 4 });

$t1->merge($t2, '/foo');

is_deeply (scalar $t1->get('/foo'),     { A => 3 });

is_deeply (scalar $t1->get('/foo/bar'), { A => 4 });


