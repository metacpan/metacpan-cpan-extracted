# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DNS-ZoneSerialNumber.t'

#########################

use Test::More tests => 49;
use strict;
use warnings;

BEGIN {
    # Override localtime globally as we rely on it to test set_from_date.
    *CORE::GLOBAL::localtime = sub (;$) {
        return ( 13, 28, 14, 20, 11, 111, 2, 353, 0 );
    };
    use_ok( 'DNS::ZoneSerialNumber' );
}

my $zsn;

$zsn = DNS::ZoneSerialNumber->new();
ok( $zsn == 1 );

ok( $zsn->set( DNS::ZoneSerialNumber->new( 14 ) ) );
ok( $zsn == 14 );

$zsn->increment();
ok( $zsn->serial == 15 );

$zsn->increment( 40 );
ok( $zsn->serial == 55 );

ok( $zsn->next() == 56 );

ok( $zsn->next( 20 ) == 75 );

ok( $zsn->serial == 55 );

$zsn->decrement( 10 );
ok( $zsn->serial == 45 );

ok( $zsn->previous == 44 );
ok( $zsn->serial == 45 );

my $compareto = '20111220';

$zsn->set_from_date();
ok( $zsn->serial == $compareto . '00' );

$zsn->set_from_date( 99 );
ok( $zsn->serial == $compareto . '99' );

$zsn->set( 4242 );
ok( $zsn->serial == 4242 );

eval { $zsn->set( 0 ); };
ok( $@ );

eval { $zsn->set( 2**32 ); };
ok( $@ );

$zsn->set( 4242 );
eval { $zsn->increment( 2**32 ); };
ok( $@ =~ /^Invalid amount/ );
undef $@;

# Make sure we didn't actually change the serial after the error.
ok( $zsn == 4242 );

ok( $zsn->compare( 10 ) == 1 );
ok( $zsn->compare( 4245 ) == -1 );
ok( $zsn->compare( 4242 ) == 0 );
$zsn->set( 1 );
ok( $zsn->compare( ( 2**32 ) - 1 ) == 1 );

ok( !$zsn->gt( 2 ) );
ok( $zsn->gte( 1 ) );
ok( $zsn->lte( 100 ) );
ok( !$zsn->lte( ( 2**32 ) - 40 ) );
ok( !$zsn->eq( 299 ) );
ok( $zsn->ne( 299 ) );

# Incomperable value pairs, as per RFC1982.
$zsn->set( 1 );
ok( !defined $zsn->compare( ( 2**31 ) + 1 ) );
# These two should be tested after the above.
ok( $zsn->incomparable == ( 2**31 ) + 1 );
ok( $zsn->is_incomparable( ( 2**31 ) + 1 ) );
$zsn->increment( 10 );
ok( !$zsn->gt( ( 2**31 ) + 11 ) );
ok( !$zsn->eq( $zsn->incomparable ) );
ok( $zsn->ne( ( 2**31 ) + 11 ) );

# Stepping tests. Sample numbers borrowed from the internet (to check my math).
$zsn->set( 1 );
ok( scalar( $zsn->steps_to_set( 2 ) ) == 1 );
is_deeply( [$zsn->steps_to_set( $zsn->incomparable )], [2147483648, 2147483649], );
$zsn->set( 2841245617 );
ok( scalar( $zsn->steps_to_set( 1693761969 ) ) == 2 );
$zsn->set( 2111012400 );
is_deeply( [$zsn->steps_to_set( 2011012400 )], [4258496047, 2011012400] );

# Mix and match parameter types, do some math.
$zsn->set( 2 );
$zsn->decrement( DNS::ZoneSerialNumber->new( $zsn - $zsn + 1 ) );
ok( $zsn == 1 );

# Overloads!
ok( $zsn == $zsn->{serial} );    # Not a supported interface.
ok( $zsn == $zsn->serial );
ok( ++$zsn == 2 );
ok( $zsn + 44 == 46 );
ok( $zsn > 1 );
ok( $zsn < $zsn + 10 );

# Ok because the increment was done in two steps, not sure this behavior is
# desirable.
ok( $zsn + DNS::ZoneSerialNumber::INCREMENT_MAX + 1 );

# Not okay because the increment was done in one step
eval { $zsn = $zsn + ( DNS::ZoneSerialNumber::INCREMENT_MAX + 1 ); };
ok( $@ =~ /^Invalid amount/ );
undef $@;

# Operator chaining AND overflow!
ok( $zsn - $zsn + 1 == 1 );

# Done!
