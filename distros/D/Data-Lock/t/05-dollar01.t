#!perl -T
#
# $Id: 05-dollar01.t,v 1.1 2014/03/07 18:24:43 dankogai Exp dankogai $
#
use strict;
use warnings;
use Data::Lock qw/dlock dunlock/;

#use Test::More 'no_plan';
use Test::More tests => 4;

dlock my $o = 0;
ok Internals::SvREADONLY($o);
ok !Internals::SvREADONLY($0);
dlock my $z = 1;
ok Internals::SvREADONLY($z);
ok !Internals::SvREADONLY($1);
