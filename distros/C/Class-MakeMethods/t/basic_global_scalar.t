#!/usr/local/bin/perl

use Test;
BEGIN { plan tests => 22 }

########################################################################

package X;

use Class::MakeMethods::Basic::Global
  scalar => [ qw / a b / ],
  scalar => 'c';

sub new { bless {}, shift; }

########################################################################

package main;

ok( 1 );

my $o = new X;
my $o2 = new X;

# 2--7
ok( ! defined $o->a );
ok( $o->a(123) );
ok( $o->a == 123 );
ok( $o2->a == 123 );
ok( ! defined $o2->a(undef) );
ok( ! defined $o->a );

# 8--13
ok( ! defined $o->b );
ok( $o->b('hello world') );
ok( $o->b eq 'hello world' );
ok( $o2->b eq 'hello world' );
ok( ! defined $o2->b(undef) );
ok( ! defined $o->b );

my $foo = 'this';
# 14--15
ok( ! defined $o->c );
ok( $o->c(\$foo) );

$foo = 'that';

# 16--22
ok( $o->c eq \$foo );
ok( $o2->c eq \$foo );
ok( ${$o->c} eq ${$o2->c});
ok( ${$o->c} eq 'that');
ok( ${$o->c} eq 'that');
ok( ! defined $o2->c(undef) );
ok( ! defined $o->c );

########################################################################

1;
