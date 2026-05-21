#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/08.infinite.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
    use_ok( 'DateTime::Lite::Infinite' ) or BAIL_OUT( 'Cannot load DateTime::Lite::Infinite' );
};

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
    ok( $fut > $pas, 'Infinite::Future > Past' );
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

# NOTE: utc_rd_values are truly infinite (PP/XS parity)
# This subtest serves to address a bug where _normalize_tai_seconds and
# _normalize_leap_seconds did not short-circuit on non-finite values in pure-Perl mode,
# causing utc_rd_days to be corrupted (-2 instead of Inf).
subtest 'utc_rd_values are truly infinite' => sub
{
    my $fut = DateTime::Lite::Infinite::Future->new;
    my $pas = DateTime::Lite::Infinite::Past->new;

    my( $fd, $fs, $fn ) = $fut->utc_rd_values;
    my( $pd, $ps, $pn ) = $pas->utc_rd_values;

    ok( $fd > 1_000_000,  'Future: utc_rd_days is very large (Inf)' );
    ok( $pd < -1_000_000, 'Past: utc_rd_days is very negative (-Inf)' );
    ok( !defined( $fn ) || $fn >= 0, 'Future: rd_nanosecs is non-negative' );
};

# NOTE: Comparison symmetry (PP regression: $fut > $now was false due to corrupted
# utc_rd_values in pure-Perl mode)
subtest 'Comparison symmetry' => sub
{
    my $now = DateTime::Lite->now( time_zone => 'UTC' );
    my $fut = DateTime::Lite::Infinite::Future->new;
    my $pas = DateTime::Lite::Infinite::Past->new;

    # Both directions must be consistent
    ok(  ( $fut > $now ), 'fut > now' );
    ok( !( $fut < $now ), 'not fut < now' );
    ok(  ( $now < $fut ), 'now < fut' );
    ok( !( $now > $fut ), 'not now > fut' );
    ok(  ( $pas < $now ), 'pas < now' );
    ok( !( $pas > $now ), 'not pas > now' );
    ok(  ( $now > $pas ), 'now > pas' );
    ok( !( $now < $pas ), 'not now < pas' );
};

done_testing;

__END__
