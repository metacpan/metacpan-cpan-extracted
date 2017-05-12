use strict;
use warnings;

use Test::More;
use Data::Couplet;
use Data::Dump qw( dump );
use Scalar::Util qw( refaddr );

sub Couplet() { 'Data::Couplet' }
my $t = 0;

sub do_test(&) {
  my $c      = shift;
  my @caller = caller();
  $caller[2]--;
  ++$t;
  eval {
    $c->();
    1;
  } or ok( 0, "Test $t mystically failed ( @ $caller[2] ) : $@" );
}

sub DEBUG() { 0 }

sub trace($) {
  note( dump(shift) );
}

my $object;

do_test {
  $object = new_ok( Couplet, [qw( a 1 b 2 c 3 d 4 e 5 f 6 )] );
  trace($object) if DEBUG;
}
for 1;

my $clone;

do_test {
  $clone = $object->clone;
  ok( defined($clone), "Clone Works" );
  trace($clone) if DEBUG;
}
for 2;

do_test {
  isnt( refaddr($object), refaddr($clone), "Clones are not the same object " );
  trace( [ refaddr($object), refaddr($clone) ] ) if DEBUG;

}
for 3;

do_test {
  $object = new_ok( Couplet, [ { hash => 'key' }, { hash => 'value' }, { hash => 'key2' }, { hash => 'value2' } ] );
}
for 4;

do_test {
  $clone = $object->clone;
  ok( defined($clone), "Cloning complex things works" );
  trace($clone) if DEBUG;
}
for 5;

do_test {
  isnt( refaddr($object), refaddr($clone), "Clones are not the same object " );
  trace( [ refaddr($object), refaddr($clone) ] ) if DEBUG;
}
for 6;

do_test {
  my ( $x, $y );
  $x = $object->key_at(0);
  $y = $clone->key_at(0);
  is( $x, $y, "Clone keys are the same" );
  trace( [ $x, $y ] ) if DEBUG;
}
for 7;

do_test {
  my ( $x, $y );
  $x = $object->key_object_at(0);
  $y = $clone->key_object_at(0);
  isnt( refaddr $x , refaddr $y , "Clone key objects are cloned" );
  trace( [ refaddr $x , refaddr $y ] ) if DEBUG;
}
for 8;

do_test {
  my ( $x, $y );
  $x = $object->value_at(0);
  $y = $clone->value_at(0);
  isnt( refaddr $x , refaddr $y , "Clone key values are cloned" );
  trace( [ refaddr $x , refaddr $y ] ) if DEBUG;
}
for 9;

done_testing($t);

