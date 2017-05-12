#!perl -T
#
# $Id: 01-atomic.t,v 1.0 2013/04/03 06:49:25 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Constant;
#use Test::More 'no_plan';
use Test::More tests => 10;

my $s : Constant(1);
is $s, 1, '$s => 1';
eval{ $s++ };
ok $@, $@;

my $c : Constant(sub { 1 });
isa_ok $c, 'CODE';
eval{ $c = sub { 0 } };
ok $@, $@;

my $g : Constant( \*STDIN);
isa_ok $g, 'GLOB';
eval{ $g = \*STDOUT };
ok $@, $@;

my $v : Constant( v1.2.3 );
is $v, v1.2.3, '$v => v1.2.3';
eval{ $v = v3.4.5 };
ok $@, $@;

my $r : Constant( qr/[perl]/ );
is $r, qr/[perl]/, '$r => qr/perl/';
eval{ $r = qr/[PERL]/ };
ok $@, $@;


__END__
SCALAR
#ARRAY
#HASH
CODE
#REF
GLOB
#LVALUE
#FORMAT
#IO
VSTRING
Regexp

