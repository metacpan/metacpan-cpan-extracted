#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cron::Toolkit;
use Cron::Toolkit::Tree::Utils qw(:all);

subtest 'unix: MON=1→2' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '30 14 * * MON', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 30 14 ? * 2 *', 'Output' );
};

subtest 'unix: SUN=7→1' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '30 14 * * SUN', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 30 14 ? * 1 *', 'Output' );
};

subtest 'unix: SAT=6→7' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '30 14 * * SAT', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 30 14 ? * 7 *', 'Output' );
};

subtest 'unix: Mon-Fri' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '* * * * MON-FRI', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 * * ? * 2-6 *', 'Output' );
};

subtest 'unix: DOM wins' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '1-5 * * * *', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 1-5 * * * ? *', 'Output' );
};

subtest 'unix: Any day' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '* * * * *', type => 'unix' ) } 'No die';
    is( $obj->{expression}, '0 * * * * ? *', 'Output' );
};

subtest 'quartz: MON=2' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '0 30 14 ? * MON *', type => 'quartz' ) } 'No die';
    is( $obj->{expression}, '0 30 14 ? * 2 *', 'Output' );
};

subtest 'quartz: 6→7' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '0 30 14 ? * 6', type => 'quartz' ) } 'No die';
    is( $obj->{expression}, '0 30 14 ? * 6 *', 'Output' );
};

subtest 'quartz: 7 fields' => sub {
    plan tests => 2;
    my $obj;
    lives_ok { $obj = Cron::Toolkit->new( expression => '0 30 14 * * ? 2025', type => 'quartz' ) } 'No die';
    is( $obj->{expression}, '0 30 14 * * ? 2025', 'Output' );
};

subtest 'unix: Too many' => sub {
    plan tests => 2;
    throws_ok { Cron::Toolkit->new( expression => '30 14 * * * MON TUE *', type => 'unix' ) } qr/expected 5-7 fields/, 'Dies';
    throws_ok { Cron::Toolkit->new( expression => '30 14 * * * MON TUE *', type => 'unix' ) } qr/expected 5-7 fields/, 'Error message';
};

subtest 'quartz: Too few' => sub {
    plan tests => 2;
    throws_ok { Cron::Toolkit->new( expression => '30 14 * *', type => 'quartz' ) } qr/expected 5-7 fields/, 'Dies';
    throws_ok { Cron::Toolkit->new( expression => '30 14 * *', type => 'quartz' ) } qr/expected 5-7 fields/, 'Error message';
};

subtest 'unix: Both DOM+DOW' => sub {
    plan tests => 2;
    throws_ok { Cron::Toolkit->new( expression => '30 14 1-5 * 1-5', type => 'unix' ) } qr/dow and dom cannot both be specified/, 'Dies';
    throws_ok { Cron::Toolkit->new( expression => '30 14 1-5 * 1-5', type => 'unix' ) } qr/dow and dom cannot both be specified/, 'Error message';
};

subtest 'new() auto-detect' => sub {
    plan tests => 2;
    my $obj1 = Cron::Toolkit->new( expression => '30 14 * * MON' );
    is( $obj1->{expression}, '0 30 14 ? * 2 *', 'Unix auto' );
    my $obj2 = Cron::Toolkit->new( expression => '0 30 14 * * ?' );
    is( $obj2->{expression}, '0 30 14 * * ? *', 'Quartz auto' );
};

subtest 'Additional edge cases' => sub {
    plan tests => 22;

    # Mixed-case names
    lives_ok { Cron::Toolkit->new( expression => '30 14 * jan Mon', type => 'unix' ) } 'No die: mixed-case single names';
    is( Cron::Toolkit->new( expression => '30 14 * jan Mon', type => 'unix' )->{expression}, '0 30 14 ? 1 2 *', 'Output: mixed-case single names' );
    lives_ok { Cron::Toolkit->new( expression => '30 14 * JaN-MaR *', type => 'unix' ) } 'No die: mixed-case month range';
    is( Cron::Toolkit->new( expression => '30 14 * JaN-MaR *', type => 'unix' )->{expression}, '0 30 14 * 1-3 ? *', 'Output: mixed-case month range' );
    lives_ok { Cron::Toolkit->new( expression => '30 14 * * mOn,WeD,fRi', type => 'unix' ) } 'No die: mixed-case dow list';
    is( Cron::Toolkit->new( expression => '30 14 * * mOn,WeD,fRi', type => 'unix' )->{expression}, '0 30 14 ? * 2,4,6 *', 'Output: mixed-case dow list' );

    # Invalid names
    throws_ok { Cron::Toolkit->new( expression => '30 14 * XYZ MON', type => 'unix' ) } qr/Invalid characters/, 'Dies: invalid month name';
    throws_ok { Cron::Toolkit->new( expression => '30 14 * JAN FOO', type => 'unix' ) } qr/Invalid characters/, 'Dies: invalid dow name';

    # Unix SUN=0
    lives_ok { Cron::Toolkit->new( expression => '30 14 * * 0', type => 'unix' ) } 'No die: SUN=0';
    is( Cron::Toolkit->new( expression => '30 14 * * 0', type => 'unix' )->{expression}, '0 30 14 ? * 1 *', 'Output: SUN=0' );

    # Unix dow steps
    lives_ok { Cron::Toolkit->new( expression => '30 14 * * 1-5/2', type => 'unix' ) } 'No die: dow step';
    is( Cron::Toolkit->new( expression => '30 14 * * 1-5/2', type => 'unix' )->{expression}, '0 30 14 ? * 2-6/2 *', 'Output: dow step' );

    # Unix dom=?
    lives_ok { Cron::Toolkit->new( expression => '30 14 ? * MON', type => 'unix' ) } 'No die: dom=?';
    is( Cron::Toolkit->new( expression => '30 14 ? * MON', type => 'unix' )->{expression}, '0 30 14 ? * 2 *', 'Output: dom=?' );

    # Unix dow=?
    lives_ok { Cron::Toolkit->new( expression => '30 14 15 * ?', type => 'unix' ) } 'No die: dow=?';
    is( Cron::Toolkit->new( expression => '30 14 15 * ?', type => 'unix' )->{expression}, '0 30 14 15 * ? *', 'Output: dow=?' );

    # Unix complex dom step
    lives_ok { Cron::Toolkit->new( expression => '30 14 1-15/5 * *', type => 'unix' ) } 'No die: dom step';
    is( Cron::Toolkit->new( expression => '30 14 1-15/5 * *', type => 'unix' )->{expression}, '0 30 14 1-15/5 * ? *', 'Output: dom step' );

    # Invalid ranges
    throws_ok { Cron::Toolkit->new( expression => '30 14 5-1 * *', type => 'unix' ) } qr/invalid dom range: 5-1/, 'Dies: invalid dom range';
    throws_ok { Cron::Toolkit->new( expression => '30 14 * * 5-1', type => 'unix' ) } qr/invalid dow range: 6-2/, 'Dies: invalid dow range';

    # Malformed inputs
    throws_ok { Cron::Toolkit->new( expression => '', type => 'unix' ) } qr/expected 5-7 fields/, 'Dies: empty input';
    throws_ok { Cron::Toolkit->new( expression => '0 30 14 * * ? * *', type => 'quartz' ) } qr/expected 5-7 fields/, 'Dies: too many fields';
};

subtest 'new_from_unix' => sub {
    lives_ok { 
        my $obj = Cron::Toolkit->new_from_unix(expression => '30 14 * * *');
        is( $obj->{expression}, '0 30 14 * * ? *', 'Basic numeric: * * * * * → 0 * * * * ? *' );
    } 'No die: basic numeric';

    lives_ok { 
        my $obj = Cron::Toolkit->new_from_unix(expression => '30 14 * * MON');
        is( $obj->{expression}, '0 30 14 ? * 2 *', 'Day name: MON → 2' );
    } 'No die: day name MON';

    lives_ok { 
        my $obj = Cron::Toolkit->new_from_unix(expression => '* * * * MON-FRI');
        is( $obj->{expression}, '0 * * ? * 2-6 *', 'Range: MON-FRI → 2-6' );
    } 'No die: DOW range';

    lives_ok { 
        my $obj = Cron::Toolkit->new_from_unix(expression => '*/10 * * * *');
        is( $obj->{expression}, '0 */10 * * * ? *', 'Step: */10 minutes' );
    } 'No die: minute step';

    throws_ok { 
        Cron::Toolkit->new_from_unix(expression => '30 14 1-5 * 1-5');
    } qr/dow and dom cannot both be specified/, 'Dies: DOM and DOW both specified';

    throws_ok { 
        Cron::Toolkit->new_from_unix(expression => '30 14 * *');
    } qr/expected 5 fields/, 'Dies: too few fields';
};

subtest 'aliases in new()' => sub {
    plan tests => 11;  # Dropped the is for @bogus
    # Valid maps (Quartz-normalized)
    lives_ok { Cron::Toolkit->new(expression => '@hourly') } 'No die: @hourly';
    is( Cron::Toolkit->new(expression => '@hourly')->{expression}, '0 0 * * * ? *', '@hourly → 0 0 * * * ? *' );
    lives_ok { Cron::Toolkit->new(expression => '@daily') } 'No die: @daily';
    is( Cron::Toolkit->new(expression => '@daily')->{expression}, '0 0 0 * * ? *', '@daily → 0 0 0 * * ? *' );
    lives_ok { Cron::Toolkit->new(expression => '@monthly') } 'No die: @monthly (L dom)';
    is( Cron::Toolkit->new(expression => '@monthly')->{expression}, '0 0 0 L ? * *', '@monthly → 0 0 0 L ? * *' );
    lives_ok { Cron::Toolkit->new(expression => '@yearly') } 'No die: @yearly';
    is( Cron::Toolkit->new(expression => '@yearly')->{expression}, '0 0 0 1 1 ? *', '@yearly → 0 0 0 1 1 ? *' );
    # Mixed: @alias + TZ
    lives_ok { Cron::Toolkit->new(expression => '@hourly', time_zone => 'UTC') } 'No die: @hourly + TZ';
    is( Cron::Toolkit->new(expression => '@hourly', time_zone => 'UTC')->utc_offset, 0, '@alias + TZ recalc' );
    # Invalid: Unknown @alias dies on field count
    throws_ok { Cron::Toolkit->new(expression => '@bogus') } qr/expected 5-7 fields/, 'Dies: unknown @alias (invalid expr)';
};

done_testing();
