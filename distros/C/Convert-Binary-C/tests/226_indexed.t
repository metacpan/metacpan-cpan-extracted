################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 45 }

my $reason = do {
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  my $c = new Convert::Binary::C OrderMembers => 1;
  (grep /Couldn't load a module for member ordering/, @w)
  ? "member ordering requires indexed hashes" : "";
};

my $order = $reason ? 0 : 1;

my @keys = grep !/do|if/, 'aa' .. 'zz';
my $members = join "\n", map "unsigned char $_;", @keys;

my $u = new Convert::Binary::C OrderMembers => 0;
my $o = new Convert::Binary::C OrderMembers => $order;

for my $c ( $u, $o ) {
  $c->parse( <<ENDC );
  struct order {
    $members
    struct {
      $members
    } foo[2];
  };
ENDC
}

my $data = pack 'C*', map { rand(256) } 1 .. $u->sizeof('order');

my $unp_u = $u->unpack( 'order', $data );
my $unp_o = $o->unpack( 'order', $data );

my $fail = 0;
my $keys = join ',', @keys;

for( @keys ) {
  $unp_u->{$_} == $unp_o->{$_} or $fail++;
  $unp_u->{foo}[0]{$_} == $unp_o->{foo}[0]{$_} or $fail++;
  $unp_u->{foo}[1]{$_} == $unp_o->{foo}[1]{$_} or $fail++;
}

ok( $fail, 0 );

skip( $reason, $keys.",foo", join(',', keys %$unp_o) );
skip( $reason, $keys, join(',', keys %{$unp_o->{foo}[0]}) );
skip( $reason, $keys, join(',', keys %{$unp_o->{foo}[1]}) );

my $list = pack 'C*', map { rand(256) } 1 .. 10*$u->sizeof('order');

my @unp_u = $u->unpack('order', $list);
my @unp_o = $o->unpack('order', $list);

ok(scalar @unp_u, scalar @unp_o);

for my $i (0 .. $#unp_u) {
  $unp_u = $unp_u[$i];
  $unp_o = $unp_o[$i];

  $fail = 0;

  for( @keys ) {
    $unp_u->{$_} == $unp_o->{$_} or $fail++;
    $unp_u->{foo}[0]{$_} == $unp_o->{foo}[0]{$_} or $fail++;
    $unp_u->{foo}[1]{$_} == $unp_o->{foo}[1]{$_} or $fail++;
  }

  ok( $fail, 0 );

  skip( $reason, $keys.",foo", join(',', keys %$unp_o) );
  skip( $reason, $keys, join(',', keys %{$unp_o->{foo}[0]}) );
  skip( $reason, $keys, join(',', keys %{$unp_o->{foo}[1]}) );
}
