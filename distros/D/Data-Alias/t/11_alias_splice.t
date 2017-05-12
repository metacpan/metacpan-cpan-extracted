#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
no warnings 'syntax';
use lib 'lib';
use Test::More tests => 35;

use Data::Alias;

sub refs { [map "".\$_, @_] }

our ($a, $b, $c, $d, $e, $f, $g);
@_ = ();

is_deeply refs(alias splice @_, 0, 0, $a, $b), [];
is_deeply &refs, refs($a, $b);
is_deeply refs(alias splice @_, 1, 0, $c, $d, $e), [];
is_deeply &refs, refs($a, $c, $d, $e, $b);
is_deeply refs(alias splice @_, 2, 1, $f, $g), refs($d);
is_deeply &refs, refs($a, $c, $f, $g, $e, $b);
is_deeply refs(alias splice @_, 1, 2, $d, $c), refs($c, $f);
is_deeply &refs, refs($a, $d, $c, $g, $e, $b);
is_deeply refs(alias splice @_, 1, 2, $f), refs($d, $c);
is_deeply &refs, refs($a, $f, $g, $e, $b);
is_deeply refs(alias splice @_, -5, 1, $c), refs($a);
is_deeply &refs, refs($c, $f, $g, $e, $b);
is_deeply refs(alias splice @_, -4, 1, $d), refs($f);
is_deeply &refs, refs($c, $d, $g, $e, $b);
is_deeply refs(alias splice @_, -1, 1, $a, $f), refs($b);
is_deeply &refs, refs($c, $d, $g, $e, $a, $f);
is_deeply refs(alias splice @_, 1, -3, $b), refs($d, $g);
is_deeply &refs, refs($c, $b, $e, $a, $f);
is_deeply refs(alias splice @_, -3, -1, $d, $g), refs($e, $a);
is_deeply &refs, refs($c, $b, $d, $g, $f);
is_deeply refs(alias splice @_, -2, -4, $e), [];
is_deeply &refs, refs($c, $b, $d, $e, $g, $f);
is_deeply refs(alias splice @_, -2, 4, $a), refs($g, $f);
is_deeply &refs, refs($c, $b, $d, $e, $a);

is_deeply refs(alias splice @_, 5, 0, $f), [];
is_deeply &refs, refs($c, $b, $d, $e, $a, $f);

eval { alias splice @_, 7, 0, $g };
like $@, qr/^splice\(\) offset past end of array /;

{
no warnings 'misc';
is_deeply refs(alias splice @_, 7, 0, $g), [];
is_deeply &refs, refs($c, $b, $d, $e, $a, $f, $g);
}

is_deeply refs(alias splice @_, 2, 1), refs($d);
is_deeply refs(alias splice @_, -3, 2), refs($a, $f);
is_deeply refs(alias splice @_, 1, -2), refs($b);
is_deeply refs(alias splice @_, -3, -2), refs($c);
is_deeply refs(alias splice @_, -1), refs($g);
is_deeply refs(alias splice @_), refs($e);

# vim: ft=perl
