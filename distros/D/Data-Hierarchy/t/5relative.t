#!/usr/bin/perl
use Test::More tests => 4;
use Test::Exception;

use strict;
use warnings;
BEGIN {
use_ok 'Data::Hierarchy';
}

my $t = Data::Hierarchy->new;
$t->store('/foo', { A => 1 });
$t->store('/foo/bar', { A => 3 });
$t->store('/foo/bar/baz', { A => 4 });

my $rel = $t->to_relative('/foo');

my $tnew = $rel->to_absolute('/beep');

is($tnew->get('/beep')->{A}, 1);
is($tnew->get('/beep/bar/baz')->{A}, 4);

throws_ok { $t->to_relative('/fo') } qr!/foo is not a child of /fo!;
