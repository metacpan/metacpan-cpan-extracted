#!perl

use 5.14.0;
use warnings;
use Test2::V0;
use Algorithm::Toy::HashSC;

########################################################################
#
# Fundamentals

my $h = Algorithm::Toy::HashSC->new;
isa_ok( $h, 'Algorithm::Toy::HashSC' );

is( scalar $h->keys, 0, 'no keys... yet.' );
is( $h->get("foo"),  undef );
is( $h->take("foo"), undef );

like dies { $h->get },       qr/must provide key/;
like dies { $h->hash },      qr/must provide key/;
like dies { $h->keys_in },   qr/must provide index/;
like dies { $h->keys_with }, qr/must provide key/;
like dies { $h->put },       qr/must provide key/;
like dies { $h->take },      qr/must provide key/;

isa_ok( $h->put( "key", 42 ), 'Algorithm::Toy::HashSC' );

is( scalar $h->keys, 1,  'one key' );
is( $h->get("key"),  42, 'get key' );
is( $h->take("key"), 42, 'take key' );
is( scalar $h->keys, 0,  'no keys' );

$h->put( "key", 99 );
$h->get("ked");    # collides with "key" for test coverage

like dies { $h->modulus(1) }, qr/modulus must be/;
# you never know, on today's Internet
like dies { $h->modulus("cat") }, qr/modulus must be/;

# NOTE using modulus resets things
$h->put( "key", 42 );
$h->modulus(2);
is( scalar $h->keys, 0, 'modulus results in no keys' );

# TODO implement
is( [ $h->keys_with("winning lotto numbers") ], [] );

for my $k (qw/a b c d e/) {
    $h->put( $k, "meh" );
}
is( [ $h->keys_with("b") ], [qw/b d/] );
is( [ $h->keys_in(0) ],     [qw/b d/] );
is( [ $h->keys_in(1) ],     [qw/a c e/] );
is( [ $h->keys ],           [qw/b d a c e/] );
$h->take("b");
is( [ $h->keys_with("d") ], [qw/d/] );
is( [ $h->keys ],           [qw/d a c e/] );
$h->take("c");
is( [ $h->keys_with("cats") ], [] );
is( [ $h->keys ],              [qw/d a e/] );
$h->take("d");
is( [ $h->keys ], [qw/a e/] );
isa_ok( $h->clear_hash, 'Algorithm::Toy::HashSC' );
is( scalar $h->keys, 0, 'no keys again' );

########################################################################
#
# Fancier Stuff

# using modulus does not reset things (in unsafe mode)
$h->put( "key", 42 );
$h->unsafe(1);
$h->modulus(13);
is( [ $h->keys ], ["key"] );

$h->unsafe(0);
$h->clear_hash;
is( scalar $h->keys, 0, 'no keys yet again' );

package FooCode {
    use Moo;
    use namespace::clean;

    # bad for hashing. good for testing.
    sub hashcode { 0 }
}
my $x = FooCode->new;
my $y = FooCode->new;
my $z = FooCode->new;

$h->put( $x, 1 );
$h->put( $y, 2 );
$h->put( $z, 3 );

is( scalar $h->keys_with($x), 3, 'all objects in same bucket' );

########################################################################
#
# I love it when a plan comes together

plan 33
