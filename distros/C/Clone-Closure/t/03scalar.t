#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Data::Dumper;
use Clone::Closure qw/clone/;

my $tests;

package Test::Scalar;

our @ISA = qw(Clone::Closure);

sub new {
    my $class = shift;
    my $self = shift;
    bless \$self, $class;
}

package main;
                                                
my $x = Test::Scalar->new(1.0);
my $y = $x->clone;

BEGIN { $tests += 2 }
cmp_ok  $$x, '==',  $$y,    'NVs clone';
isnt    $x,         $y,     '...not copy';

my $c = \"test 2 scalar";
my $d = clone $c;

BEGIN { $tests += 2 }
is      $$c,    $$d,            'refs clone';
isnt    $c,     $d,             '...not copy';

my $circ = undef;
$circ = \$circ;
my $aref = clone $circ;

BEGIN { $tests += 1 }
is  Dumper($circ), Dumper($aref), 'circular refs clone';

# the following used to produce a segfault, rt.cpan.org id=2264
undef $x;
$y = clone $x;

BEGIN { $tests += 1 }
ok  !defined($y),               'undef clones';

# used to get a segfault cloning a ref to a qr data type.
my $str = 'abcdefg';
my $qr = qr/$str/;
my $qc = clone $qr;

BEGIN { $tests += 2 }
is      $qr,    $qc,            'qr clones';
like    $str,   $qc,            'cloned qr matches'; 

# test for unicode support
{
    my $a = \( chr(256) );
    my $b = clone $a;

    BEGIN { $tests += 1 }
    is ord($$a), ord($$b),      'ref to unicode clones';
}

BEGIN { plan tests => $tests }
