################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 8 }

tie @a1, 'Tie::Array::CBCTest';
tie @a2, 'Tie::Array::CBCTest';
tie @a3, 'Tie::Array::CBCTest';
tie @a4, 'Tie::Array::CBCTest';
tie %h1, 'Tie::Hash::CBCTest';
tie %h2, 'Tie::Hash::CBCTest';

tie @a, 'Tie::Array::CBCTest';
tie %h, 'Tie::Hash::CBCTest';

@a1 = ( 1 .. 4 );
@a2 = ( 4, 5 );
@a3 = ( 7, 8 );

%h1 = ( i => 3, c => \@a2 );
%h2 = ( i => 6, c => \@a3 );

@a4 = ( \%h1, \%h2 );

%h = ( foo => 1, bar => 2, baz => \@a1, xxx => \@a4 );

$ref = { foo => 2, bar => 3, baz => [2 .. 5],
         xxx => [ { i => 4, c => [5, 6] }, { i => 7, c => [8, 9] } ] };

$c = Convert::Binary::C->new->parse( <<ENDC );

struct tie {
  int foo;
  int bar;
  int baz[4];
  struct {
    int  i;
    char c[2];
  } xxx[2];
};

ENDC

$p1 = $c->pack('tie', \%h);
$p2 = $c->pack('tie', $ref);
ok( $p1, $p2 );

$p1 = $c->pack('tie.baz', $h{baz});
$p2 = $c->pack('tie.baz', $ref->{baz});
ok( $p1, $p2 );

$p1 = $c->pack('tie.xxx[0]', $h{xxx}[0]);
$p2 = $c->pack('tie.xxx[0]', $ref->{xxx}[0]);
ok( $p1, $p2 );

$i1 = $c->initializer('tie', \%h);
$i2 = $c->initializer('tie', $ref);
ok( $i1, $i2 );

$i1 = $c->initializer('tie.baz', $h{baz});
$i2 = $c->initializer('tie.baz', $ref->{baz});
ok( $i1, $i2 );

$i1 = $c->initializer('tie.xxx[0]', $h{xxx}[0]);
$i2 = $c->initializer('tie.xxx[0]', $ref->{xxx}[0]);
ok( $i1, $i2 );

@a = ('FOO=42');
$c->configure( Define => \@a );
$c->parse( 'typedef char zaphod[FOO];' );
ok( $c->sizeof('zaphod'), 42 );

@a = sort qw( const inline restrict );
$c->configure( DisabledKeywords => \@a );
$b = $c->configure( 'DisabledKeywords' );
ok( "@a", "@$b" );


package Tie::Hash::CBCTest;

sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FETCH    { my $x = $_[0]->{$_[1]}; ref $x || $x =~ /\D/ ? $x : $x+1 }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }

package Tie::Array::CBCTest;

sub TIEARRAY  { bless [], $_[0] }
sub EXTEND    { }
sub FETCHSIZE { scalar @{$_[0]} }
sub STORESIZE { $#{$_[0]} = $_[1]-1 }
sub STORE     { $_[0]->[$_[1]] = $_[2] }
sub FETCH     { my $x = $_[0]->[$_[1]]; ref $x || $x =~ /\D/ ? $x : $x+1 }
sub CLEAR     { @{$_[0]} = () }
sub POP       { pop(@{$_[0]}) }
sub PUSH      { my $o = shift; push(@$o,@_) }
sub SHIFT     { shift(@{$_[0]}) }
sub UNSHIFT   { my $o = shift; unshift(@$o,@_) }
# sub EXISTS    { defined $_[0]->[$_[1]] } # exists doesn't work for < 5.6.0
# sub DELETE    { undef $_[0]->[$_[1]] }   # delete doesn't work for < 5.6.0

sub SPLICE
{
 my $ob  = shift;
 my $sz  = $ob->FETCHSIZE;
 my $off = @_ ? shift : 0;
 $off   += $sz if $off < 0;
 my $len = @_ ? shift : $sz-$off;
 return splice(@$ob,$off,$len,@_);
}
