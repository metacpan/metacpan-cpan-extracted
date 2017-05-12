#!/usr/bin/perl

package Y;

sub new { bless {}, shift; }
sub foo { $_[0]->{foo} = $_[1] if $#_; $_[0]->{foo} }

package X;

use Test;
BEGIN { plan tests => 14 }
use Tie::RefHash;

use Class::MakeMethods::Template::Hash
  'tiedhash' => [
	       a => {
		     'tie'	=> qw/ Tie::RefHash /,
		     'args' => [],
		    },
	       b => {
		     'tie'	=> qw/ Tie::RefHash /,
		     'args' => [],
		    },
	      ];

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ); #1
ok( ! scalar keys %{$o->a} ); #2
ok( ! defined $o->a('foo') ); #3
ok( $o->a_push('foo', 'baz') ); #4
ok( $o->a('foo') eq 'baz' ); #5
ok( $o->a_push('bar', 'baz2') ); #6
ok sub {
  my @l = $o->a([qw / foo bar / ]);
  $l[0] eq 'baz' and $l[1] eq 'baz2'
};

ok( $o->a_push(qw / a b c d / ) ); #7
ok sub {
  my @l = sort keys %{$o->a};
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo'
};

ok sub {
  my @l = sort $o->a_keys;
  $l[0] eq 'a' and
  $l[1] eq 'bar' and
  $l[2] eq 'c' and
  $l[3] eq 'foo'
};

ok sub {
  my @l = sort $o->a_values;
  $l[0] eq 'b' and
  $l[1] eq 'baz' and
  $l[2] eq 'baz2' and
  $l[3] eq 'd'
};

ok( $o->b_tally(qw / a b c a b a d / ) ); #8
ok sub {
  my %h = $o->b;
  $h{'a'} == 3 and
  $h{'b'} == 2 and
  $h{'c'} == 1 and
  $h{'d'} == 1
};

# Test use of tie...
ok sub {
  my $y1 = new Y;
  my $y2 = new Y;
  $y2->foo ("test");
  $o->b ( $y1 => $y2 );
  $o->b ($y1)->foo eq "test";
};

exit 0;

