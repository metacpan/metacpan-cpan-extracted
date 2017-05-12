#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 48;

use Data::Alias;

sub refs { [map "".\$_, @_] }
sub ckvoid { ok !defined wantarray }
sub context : lvalue { my $x = defined(wantarray) ? 1 + wantarray : 0; $x }

our ($x, $y);

no warnings 'void';

# context
is alias(context), 1;
is +(alias context)[0], 2;

# do-blocks
is alias { context }, 1;
is +(alias { context })[0], 2;
is \alias { undef }, \undef;
is \alias { ckvoid; $x, $y }, \$y;
is \alias { do { ckvoid; $x, $y } }, \$y;
is_deeply refs(alias { do { ckvoid; $x, $y, undef } }), refs($x, $y, undef);
is alias { local $_ = 42 }, 42;

# verify curpm
0 =~ /(0)/;
is $1, 0;
alias { 42 =~ /(42)/; is $1, 42 };
is $1, 0;
alias { our $z; local $z = 1 =~ /(1)/ until $1; ok !$z; is $1, 1 };
is $1, 0;

# leavesub.. actually calls alias_pp_return for all the hard work
alias sub { ckvoid }->();
alias(sub { ckvoid })->();
is alias(sub { context }->()), 1;
is alias(sub { context })->(), 1;
is \alias(sub { $x, $y }->()), \$y;
is \alias(sub { $x, $y })->(), \$y;
is +(alias sub { context }->())[0], 2;
is +(alias(sub { context })->())[0], 2;
is_deeply refs(alias sub { $x, $y }->()),  refs($x, $y);
is_deeply refs(alias(sub { $x, $y })->()), refs($x, $y);

# leavesublv and leavetry call enter too... mostly tested, so keep it brief
alias(sub : lvalue { ckvoid; $x })->();
is \alias(sub : lvalue { $x, $y })->(), \$y;
is_deeply refs(alias(sub : lvalue { $x, $y })->()), refs($x, $y);
alias(eval { ckvoid });
is \alias(eval { $x, $y }), \$y;
is_deeply refs(alias eval { $x, $y }), refs($x, $y);

# entereval / leaveeval
alias(eval 'ckvoid');
is alias(eval 'context'), 1;
is \alias(eval '$x, $y'), \$y;
is +(alias eval 'context')[0], 2;
is_deeply refs(alias eval '$x, $y'), refs($x, $y);

# return itself.. mostly tested already, so keep it brief
is \sub { alias return $x, $y }->(), \$y;
is_deeply refs(sub { alias return $x, $y }->()), refs($x, $y);
is \sub : lvalue { alias return $x, $y }->(), \$y;
is_deeply refs(sub : lvalue { alias return $x, $y }->()), refs($x, $y);
is \eval { alias return $x, $y }, \$y;
is_deeply refs(eval { alias return $x, $y }), refs($x, $y);
is \eval 'alias return $x, $y', \$y;
is_deeply refs(eval 'alias return $x, $y'), refs($x, $y);
is \sub { for (1) { alias return $x, $y } }->(), \$y;

# vim: ft=perl
