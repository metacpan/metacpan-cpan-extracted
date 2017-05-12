#!/usr/bin/perl -w

use Test::More qw(no_plan);
use Scalar::Util qw(weaken isweak);
use warnings;
use strict;

my $a;
my $b = \$a;

ok(! isweak($b), "b not weak");
weaken($b);
ok(isweak($b), "b weak");

my $x = { y => [ 0, 1, 2], z => \$a, w => { a => 7 } };

my $strong = { %$x };

ok(! isweak($x->{z}), "z not weak");
weaken($x->{z});
ok(isweak($x->{z}), "z weak");

ok(! isweak($x->{y}), "y not weak");
weaken($x->{y});
ok(isweak($x->{y}), "y weak");

ok(! isweak($x->{w}), "w not weak");
weaken($x->{w});
ok(isweak($x->{w}), "w weak");

my $copy = $x;

ok(isweak($copy->{z}), "copy z weak");
ok(isweak($copy->{w}), "copy w weak");
ok(isweak($copy->{y}), "copy y weak");

undef $strong;

ok(! defined($copy->{w}), "w undef");
ok(! defined($copy->{y}), "y undef");

