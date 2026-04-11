#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/08.infinite.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
use_ok( 'DateTime::Lite::Infinite' ) or BAIL_OUT( 'Cannot load DateTime::Lite::Infinite' );

# NOTE: Basic construction
subtest 'Basic construction' => sub
{
    my $fut = DateTime::Lite::Infinite::Future->new;
    ok( defined( $fut ), 'Infinite::Future->new works' );
    isa_ok( $fut, 'DateTime::Lite::Infinite::Future' );
    isa_ok( $fut, 'DateTime::Lite::Infinite' );
    isa_ok( $fut, 'DateTime::Lite' );

    my $pas = DateTime::Lite::Infinite::Past->new;
    ok( defined( $pas ), 'Infinite::Past->new works' );
    isa_ok( $pas, 'DateTime::Lite::Infinite::Past' );
};

# NOTE: Singletons
subtest 'Singletons' => sub
{
    my $f1 = DateTime::Lite::Infinite::Future->new;
    my $f2 = DateTime::Lite::Infinite::Future->new;
    is( $f1, $f2, 'Future is a singleton' );

    my $p1 = DateTime::Lite::Infinite::Past->new;
    my $p2 = DateTime::Lite::Infinite::Past->new;
    is( $p1, $p2, 'Past is a singleton' );
};

# NOTE: is_finite / is_infinite
subtest 'is_finite / is_infinite' => sub
{
    my $fut = DateTime::Lite::Infinite::Future->new;
    ok( $fut->is_infinite, 'Future: is_infinite' );
    ok( !$fut->is_finite,  'Future: not is_finite' );

    my $pas = DateTime::Lite::Infinite::Past->new;
    ok( $pas->is_infinite, 'Past: is_infinite' );
    ok( !$pas->is_finite,  'Past: not is_finite' );
};

# NOTE: Mutating methods are no-ops
subtest 'Mutating methods are no-ops' => sub
{
    my $fut = DateTime::Lite::Infinite::Future->new;
    my $ret = $fut->set_time_zone( 'UTC' );
    is( $ret, $fut, 'set_time_zone on Infinite returns self' );

    $ret = $fut->truncate( to => 'day' );
    is( $ret, $fut, 'truncate on Infinite returns self' );
};

# NOTE: Comparison: Infinite > any normal datetime
subtest 'Comparison: Infinite > any normal datetime' => sub
{
    my $now = DateTime::Lite->now( time_zone => 'UTC' );
    my $fut = DateTime::Lite::Infinite::Future->new;
    my $pas = DateTime::Lite::Infinite::Past->new;

    ok( $fut > $now, 'Infinite::Future > now' );
    ok( $pas < $now, 'Infinite::Past < now' );
    ok( $fut > $pas, 'Future > Past' );
};

# NOTE: Adding an infinite duration to a normal datetime -> Infinite
subtest 'Adding an infinite duration to a normal datetime -> Infinite' => sub
{
    my $dt  = DateTime::Lite->now( time_zone => 'UTC' );
    my $dur = DateTime::Lite::Duration->new(
        seconds => DateTime::Lite::INFINITY()
    );
    $dt->add_duration( $dur );
    isa_ok( $dt, 'DateTime::Lite::Infinite::Future',
        'Adding infinite duration yields Infinite::Future' );
};

done_testing;

__END__
