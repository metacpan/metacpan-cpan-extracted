use strict;
use warnings;

use Test::More;
use Data::Couplet;
use Data::Dump qw( dump );

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
  $object = new_ok(Couplet);
  trace($object) if DEBUG;
}
for 1 .. 2;

do_test {
  $object->set( "Hello", "World" );
  is( $object->value("Hello"), "World", "Data Storage Works" );
  trace($object) if DEBUG;
}
for 3 .. 4;

do_test {    #
  my $key = ["Magical Hash"];
  $object->set( $key, "World" );
  is( $object->value($key), "World", "Data Storage Works(Object Key)" );
  trace($object) if DEBUG;
}
for 5 .. 6;

do_test {
  my @values = $object->keys;
  is_deeply( \@values, [ "Hello", ["Magical Hash"], ["Magical Hash"] ], "Keys Retain Data" );
  trace( \@values ) if DEBUG;
}
for 7 .. 8;

do_test {
  my @values = $object->values;
  is_deeply( \@values, [ "World", "World", "World" ], '->values returns the right stuff' );
  trace( \@values ) if DEBUG;
}
for 9 .. 10;

do_test {
  $object = new_ok( Couplet, [ 'A' => 'B', 'C' => 'D' ] );
  trace($object) if DEBUG;
}
for 11;

do_test {
  is_deeply( [ $object->values ], [ 'B', 'D' ], 'Values Maintain Order' );
}
for 12;

do_test {
  is_deeply( [ $object->keys ], [ 'A', 'C' ], 'Keys Maintain Order' );
}
for 13;

do_test {
  $object = new_ok( Couplet, [qw( A B C D E F G H I J K L )] );
  trace($object) if DEBUG;
}
for 14;

do_test {
  $object->unset('A');
  my @values = $object->values;
  is_deeply( \@values, [qw( D F H J L )], "Delete Head" );
  trace($object) if DEBUG;
  trace( \@values ) if DEBUG;
}
for 15;

do_test {
  $object->unset('E');
  my @values = $object->values;
  is_deeply( \@values, [qw( D H J L )], "Delete Second" );
  trace($object) if DEBUG;
  trace( \@values ) if DEBUG;
}
for 16;

do_test {
  $object->unset('K');
  my @values = $object->values;
  is_deeply( \@values, [qw( D H J )], "Delete Last" );
  trace($object) if DEBUG;
  trace( \@values ) if DEBUG;
}
for 17;

do_test {
  $object->unset('C');
  $object->unset('G');
  $object->unset('I');
  my @values = $object->values;
  is_deeply( \@values, [qw()], "Delete All" );
  trace($object) if DEBUG;
  trace( \@values ) if DEBUG;
}
for 18;

do_test {
  $object->unset('C');
  $object->unset('G');
  $object->unset('I');
  my @values = $object->values;
  is_deeply( \@values, [qw()], "Delete Imaginary" );
  trace($object) if DEBUG;
  trace( \@values ) if DEBUG;
}
for 18;

done_testing($t);

