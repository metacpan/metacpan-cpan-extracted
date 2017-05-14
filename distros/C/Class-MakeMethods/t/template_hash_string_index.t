#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 17 }

use Class::MakeMethods::Template::Hash (
  'string_index' => [ qw / a b / ],
  'string_index' => 'c'
);

sub new { bless {}, shift; }
my $o = new X;
my $o2 = new X;

ok( 1 ); #1

ok( $o->a(123) ); #2
ok( $o->a == 123 ); #3
ok( X->find_a(123) eq $o ); #4
ok sub {
  $o2->a(456);
  my @f = X->find_a(123, 456);
  $f[0] eq $o or return 0;
  $f[1] eq $o2 or return 0;
};

ok( $o->a('foo') ); #5
ok( ! defined X->find_a(123) ); #6
ok( X->find_a('foo') eq $o ); #7
ok( $o->a(456) ); #8
ok( X->find_a(456) eq $o ); #9

my $h;
$o2->a(789);
ok( $h = X->find_a ); #10
ok( ref $h eq 'HASH' ); #11
ok( scalar keys %$h == 2 ); #12
ok( $h->{456} eq $o ); #13
ok( $h->{789} eq $o2 ); #14

ok( ! $o2->clear_a ); #15
ok( ! defined X->find_a(789) ); #16

exit 0;

