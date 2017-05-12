
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

my @data = ();

for ( 0 .. 40 ) {
  my $key   = join '', map { chr( int( rand(24) ) + ord('A') - 1 ) } 0 .. 5;
  my $value = join '', map { chr( int( rand(24) ) + ord('a') - 1 ) } 0 .. 5;
  push @data, $key, $value;
}

my @i = sort { rand(50) <=> rand(50) } 0 .. 40;
my @j = grep { rand(50) > 25 } @i;
my $k = -1;
my %m;
@m{@j} = ();

my @l = grep { $k++; !exists $m{$k} } map { $data[ $_ * 2 ] } 0 .. 40;

my $object;
do_test {
  $object = Couplet->new(@data);
  isa_ok( $object, Couplet );
};

do_test {
  $object->unset_at(@i);
  is_deeply( [ $object->keys() ], [], 'Data now empty' ) || diag explain [$object];
};

do_test {
  $object = Couplet->new(@data);
  isa_ok( $object, Couplet );
};

do_test {
  $object->unset_at(@j);
  is_deeply( [ $object->keys() ], [@l], 'Random Degradation is still solid' ) || diag explain [ $object, \@l ];
};

done_testing($t);

#dump \@i;

