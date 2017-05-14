#!/usr/local/bin/perl

use Test;
BEGIN { plan tests => 15 }

########################################################################

package X;

use lib qw ( ./t );
use Test;

use Class::MakeMethods::Basic::Global ( hash => [ 'a', 'c' ] );

sub new { bless {}, shift; }

########################################################################

package main;

ok( 1 );

my $o = new X;
my $o2 = new X;

ok( ! scalar keys %{$o->a} );
ok( ! defined $o->a('foo') );
ok( $o->a('foo', 'baz') );
ok( $o->a('foo') eq 'baz' );
ok( $o->a('bar', 'baz2') );

{
  my @l = $o->a([qw / foo bar / ]);
  ok(
    $l[0] eq 'baz' and $l[1] eq 'baz2'
  );
}
ok( $o->a(qw / a b c d / ) );
{
  my %h = %{ $o->a };
  my @l = sort keys %h;
  ok(
    $l[0] eq 'a' and
    $l[1] eq 'bar' and
    $l[2] eq 'c' and
    $l[3] eq 'foo'
  );
}

{
  my %h=('w' => 'x', 'y' => 'z');
  ok(
    my $r = $o->a(%h)
  );
}

{
  my @l = sort keys %{ $o->a };
  ok(
    $l[0] eq 'a' and
    $l[1] eq 'bar' and
    $l[2] eq 'c' and
    $l[3] eq 'foo' and
    $l[4] eq 'w' and
    $l[5] eq 'y'
  );
}

{
  my @l = sort values %{ $o->a };
  ok(
    $l[0] eq 'b' and
    $l[1] eq 'baz' and
    $l[2] eq 'baz2' and
    $l[3] eq 'd' and
    $l[4] eq 'x' and
    $l[5] eq 'z'
  );
}

ok( ! defined $o->c('foo') );
ok( defined $o->c );

ok( $o->a eq $o2->a );

########################################################################

1;
