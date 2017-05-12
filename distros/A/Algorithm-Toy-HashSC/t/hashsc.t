#!perl

use 5.014000;
use warnings;

use Test::More;    # plan is down at bottom
use Test::Exception;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

use Algorithm::Toy::HashSC;

########################################################################
#
# Fundamentals

my $h = Algorithm::Toy::HashSC->new;
isa_ok( $h, 'Algorithm::Toy::HashSC' );

is( scalar $h->keys, 0, 'no keys... yet.' );

isa_ok( $h->put( "key", 42 ), 'Algorithm::Toy::HashSC' );

is( scalar $h->keys, 1,  'one key' );
is( $h->get("key"),  42, 'get key' );
is( $h->take("key"), 42, 'take key' );
is( scalar $h->keys, 0,  'no keys' );

dies_ok( sub { $h->modulus(1) }, 'modulus must be > 1' );
# you never know, on today's Internet
dies_ok( sub { $h->modulus("cat") }, 'modulus must not be a cat' );

# using modulus resets things
$h->put( "key", 42 );
$h->modulus(2);
is( scalar $h->keys, 0, 'modulus results in no keys' );

# TODO implement
$deeply->( [ $h->keys_with("winning lotto numbers") ], [] );

for my $k (qw/a b c d e/) {
  $h->put( $k, "meh" );
}
$deeply->( [ $h->keys_with("b") ], [qw/b d/] );
$deeply->( [ $h->keys_in(0) ], [qw/b d/] );
$deeply->( [ $h->keys_in(1) ], [qw/a c e/] );
$deeply->( [ $h->keys ], [qw/b d a c e/] );
$h->take("b");
$deeply->( [ $h->keys_with("d") ], [qw/d/] );
$deeply->( [ $h->keys ], [qw/d a c e/] );
$h->take("c");
$deeply->( [ $h->keys_with("cats") ], [] );
$deeply->( [ $h->keys ], [qw/d a e/] );
$h->take("d");
$deeply->( [ $h->keys ], [qw/a e/] );
isa_ok( $h->clear_hash, 'Algorithm::Toy::HashSC' );
is( scalar $h->keys, 0, 'no keys again' );

########################################################################
#
# Fancier Stuff

# using modulus does not reset things (in unsafe mode)
$h->put( "key", 42 );
$h->unsafe(1);
$h->modulus(13);
$deeply->( [ $h->keys ], ["key"] );

$h->unsafe(0);
$h->clear_hash;
is( scalar $h->keys, 0, 'no keys yet again' );

package FooCode {
  use Moo;
  use namespace::clean;

  # bad for hashing. good for testing.
  sub hashcode { 0 };
}
my $x = FooCode->new;
my $y = FooCode->new;
my $z = FooCode->new;

$h->put($x, 1);
$h->put($y, 2);
$h->put($z, 3);

is( scalar $h->keys_with($x), 3, 'all objects in same bucket' );

########################################################################
#
# I love it when a plan comes together

plan tests => 25;
