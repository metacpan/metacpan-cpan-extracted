
use strict;
use Module::Load qw(load);
use Test::More;

my ( $dh, $holidays_hashref );

use lib qw(lib ../lib);

use_ok('Date::Holidays');

SKIP: {
    eval { load Date::Holidays::DK };
    skip "Date::Holidays::DK not installed", 6 if ($@);

    eval { load Date::Holidays::NO };
    skip "Date::Holidays::NO not installed", 6 if ($@);

    $dh = Date::Holidays->new( countrycode => 'dk' );

    isa_ok( $dh, 'Date::Holidays', 'Testing Date::Holidays object' );

    ok( $dh->is_holiday(
            year  => 2004,
            month => 12,
            day   => 25
        ),
        'Testing whether 1. christmas day is a holiday in DK'
    );

    ok( $holidays_hashref = $dh->is_holiday(
            year      => 2004,
            month     => 12,
            day       => 25,
            countries => [ 'no', 'dk' ],
        ),
        'Testing whether 1. christmas day is a holiday in NO and DK'
    );

    is( keys %{$holidays_hashref},
        2, 'Testing to see if we got two definitions' );

    ok( $holidays_hashref->{'dk'}, 'Testing whether DK is set' );
    ok( $holidays_hashref->{'no'}, 'Testing whether NO is set' );
}

ok( $holidays_hashref = Date::Holidays->is_holiday(
        year  => 2014,
        month => 12,
        day   => 25,
    ),
    'Testing is_holiday called without an object'
);

SKIP: {
    eval { load Date::Holidays::PT };
    skip "Date::Holidays::PT not installed", 2 if $@;

    ok( $holidays_hashref->{'pt'},
        'Checking for Portuguese first day of year' );

    can_ok('Date::Holidays::PT', qw(holidays is_holiday));
}

SKIP: {
    eval { load Date::Holidays::BR };
    skip "Date::Holidays::BR not installed", 2 if $@;

    ok( $holidays_hashref->{'br'},
        'Checking for Brazillian first day of year' );

    can_ok('Date::Holidays::BR', qw(holidays is_holiday));
}

SKIP: {
    eval { load Date::Holidays::AU };
    skip "Date::Holidays::AU not installed", 4 if $@;

    ok( $holidays_hashref->{'au'},
        'Checking for Australian christmas' );

    can_ok('Date::Holidays::AU', qw(holidays is_holiday));

    ok(my $au = Date::Holidays->new(countrycode => 'au'));

    ok($au->is_holiday(
        day   => 9,
        month => 3,
        year  => 2015,
        state => 'TAS',
    ), 'Asserting 8 hour day in Tasmania, Australia');
}

SKIP: {
    eval { load Date::Holidays::AT };
    skip "Date::Holidays::AT not installed", 3 if $@;

    ok( !$holidays_hashref->{'at'},
        'Checking for Austrian first day of year' );

    ok(! Date::Holidays::AT->can('is_holiday'));
    can_ok('Date::Holidays::AT', qw(holidays));
}

SKIP: {
    eval { load Date::Holidays::PL };
    skip "Date::Holidays::PL not installed", 3 if $@;

    ok( $holidays_hashref->{'pl'},
        'Checking for Polish first day of year' );

    ok(Date::Holidays::PL->can('is_holiday'));
    ok(Date::Holidays::PL->can('holidays'));
}

SKIP: {
    eval { load Date::Holidays::ES };
    skip "Date::Holidays::ES not installed", 2 if $@;

    ok( $holidays_hashref->{'es'}, 'Checking for Spanish christmas' );

    can_ok('Date::Holidays::ES', qw(holidays is_holiday));
}

SKIP: {
    eval { load Date::Holidays::NZ };
    skip "Date::Holidays::NZ not installed", 3 if $@;

    ok( $holidays_hashref->{'nz'}, 'Checking for New Zealandian christmas' );

    ok(! Date::Holidays::NZ->can('holidays'));
    ok(! Date::Holidays::NZ->can('is_holiday'));
}

SKIP: {
    eval { load Date::Holidays::NO };
    skip "Date::Holidays::NO not installed", 2 if $@;

    ok( $holidays_hashref->{'no'}, 'Checking for Norwegian christmas' );

    can_ok('Date::Holidays::NO', qw(holidays is_holiday));
}

SKIP: {
    eval { load Date::Holidays::FR };
    skip "Date::Holidays::FR not installed", 3 if $@;

    ok( $holidays_hashref->{'fr'}, 'Checking for French christmas' );

    ok(! Date::Holidays::FR->can('holidays'));
    ok(! Date::Holidays::FR->can('is_holiday'));
}

SKIP: {
    eval { load Date::Holidays::KR };
    skip "Date::Holidays::KR not installed", 3 if $@;

    ok(! $holidays_hashref->{'kr'}, 'Checking for Korean holiday' );

    ok(Date::Holidays::KR->can('holidays'));
    ok(Date::Holidays::KR->can('is_holiday'));
}

SKIP: {
    eval { load Date::Holidays::CN };
    skip "Date::Holidays::CN not installed", 3 if $@;

    ok( $holidays_hashref->{'cn'},
        'Checking for Chinese first day of year' );

    ok(! Date::Holidays::CN->can('holidays'));
    ok(! Date::Holidays::CN->can('is_holiday'));
}

SKIP: {
    eval { load Date::Holidays::GB };
    skip "Date::Holidays::GB not installed", 7 if $@;

    ok( $holidays_hashref->{'gb'}, 'Checking for English holiday' );
    
    can_ok('Date::Holidays::GB', qw(holidays is_holiday));

    ok( my $holidays_hashref_sct = Date::Holidays::GB::holidays(year => 2014, regions => ['SCT']));

    ok( my $holidays_hashref_eaw = Date::Holidays::GB::holidays(year => 2014, regions => ['EAW']));

    ok( keys %{$holidays_hashref_eaw} != keys %{$holidays_hashref_sct});

    ok(my $gb = Date::Holidays->new(countrycode => 'gb'));

    ok($gb->is_holiday(
        day   => 17,
        month => 3,
        year  => 2015,
        region => 'NIR',
    ), 'Asserting St Patrick’s Day in Northern Ireland');

}


SKIP: {
    eval { load Date::Holidays::RU };
    skip "Date::Holidays::RU not installed", 3 if $@;

    my $holidays_hashref = Date::Holidays->is_holiday(
        year  => 2015,
        month => 1,
        day   => 7,
        countries => [ 'ru' ],
    );

    ok( $holidays_hashref->{ru}, 'Checking for Russian christmas' );

    ok( Date::Holidays::RU->can('holidays') );
    ok( Date::Holidays::RU->can('is_holiday') );
}

done_testing();
