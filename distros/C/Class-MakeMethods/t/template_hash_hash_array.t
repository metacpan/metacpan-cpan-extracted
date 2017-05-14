#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 20 }

use Class::MakeMethods::Template::Hash (
  'hash_of_arrays' => [ qw / a b / ],
  'hash_of_arrays' => 'c'
);

sub new { bless {}, shift; }
my $o = new X;

# 1--2
ok( ! scalar @{$o->a} ); #1
ok do { my @a = $o->a ('foo'); scalar @a == 0 }; #2

# 3
$o->a_push ('foo', 'biff');
ok do {
  my @a = $o->a ('foo'); @a == 1 and $a[0] eq 'biff'
};

# 4
$o->a_push ('bar', 'glarch');
$o->a_push ('wiz', 'lark');
ok do {
  my @l = $o->a ([qw/ foo bar /]);
  @l == 2 and $l[0] eq 'biff' and $l[1] eq 'glarch'
};

# 5
ok do {
  my %x = map {$_,1} qw( biff glarch lark );
  my $l;
  my $ok = 1;
  foreach $l ($o->a) {
    $ok = 0 if ! exists $x{$l};
    delete $x{$l};
  }
  $ok &&= keys %x == 0;
};


# 6
ok do {
  $o->a_push('foo', qw / a b c d / );
  my @l = sort $o->a;

  $l[0] eq 'a' and
    $l[1] eq 'b' and
      $l[2] eq 'biff' and
	$l[3] eq 'c' and
	  $l[4] eq 'd' and
	    $l[5] eq 'glarch'
};

# 7
ok do {
  my @l = sort $o->a_splice ('foo', 1, 3);
  $l[0] eq 'a' and
    $l[1] eq 'b' and
      $l[2] eq 'c'
};

# 8
$o->a_clear(qw / foo bar / );
ok do {
  my @a = $o->a;
  @a == 1 and $a[0] eq 'lark';
};

# 9--10
$o->c_push ('foo', 'bar');
ok( ($o->c ('foo'))[0] eq 'bar' ); #3
$o->c_delete('foo');
ok do { my @a = $o->c('foo'); @a == 0 }; #4

# 11--15
my @keys = qw/a b c/;
$o->c_push ([@keys],qw/ d e f /);
ok do {
  ($o->c ('a'))[2] eq 'f'
    and ($o->c ('b'))[1] eq 'e'
      and ($o->c ('c'))[0] eq 'd'
};
ok do {
  my @k = sort $o->c_keys;
  my $ok = (@k == @keys);
  for (0..$#k) {
    $ok &&= ( $k[$_] eq $keys[$_] );
  }
  $ok;
};
ok do {
  $o->c_exists (@keys);
};
ok do {
  @a = $o->c_pop (@keys);
  my $ok = (@a == @keys);
  for (@a) {
    $ok &&= $_ eq 'f';
  }
  $ok;
};
ok do {
  ! $o->c_exists (@keys, 'duck');
};


# 16
ok do {
  $o->c_delete(qw/ a c /);
  my @a = $o->c_keys;
  @a == 1 and $a[0] eq 'b';
};

# 17
$o->c_unshift ([qw/ b c /], 'e');
ok do {
  my @a = $o->c (qw/ c b /);
  my @expect = qw/ e e d e /;
  my $ok = @a == @expect;
  for (0..$#a) {
    $ok &&= $a[$_] eq $expect[$_];
  }
   $ok;
};

# 18
$o->c_shift (qw/ b /);
ok do {
  my @a = $o->c (qw/ c b /);
  my @expect = qw/ e d e /;
  my $ok = @a == @expect;
  for (0..$#a) {
    $ok &&= $a[$_] eq $expect[$_];
  }
  $ok;
};

# 19--20
$o->c_splice ('b', 1, 0, 'e');
$o->c_splice ('b', 0, 1);
ok do {
  my @a = $o->c (qw/ c b /);
  my @expect = qw/ e e e /;
  my $ok = @a == @expect;
  for (0..$#a) {
    $ok &&= $a[$_] eq $expect[$_];
  }
  $ok;
};
ok do {
  $o->c_count (qw/ c b /) == 3;
};

exit 0;

