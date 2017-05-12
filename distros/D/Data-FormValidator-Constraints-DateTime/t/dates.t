use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
my $DFV_4 = $Data::FormValidator::VERSION =~ /^4\./ ? 1 : 0;
# only run these tests if we have D::FV 4.x
if( $DFV_4 ) {
    plan(tests => 61);
} else {
    plan(skip_all => 'D::FV 4.x not installed');
}

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import(':all');
my $format          = '%m-%d-%Y';
my $good_date       = '02-17-2005';
my $unreal_date     = '02-31-2005';
my $bad_date        = '0-312-005';
my $real_bad_date   = '2';
my $today           = DateTime->today->mdy('-');
# these are relative to the above $good_date;
my $distant_future_date = DateTime->today->add(years => 100)->mdy('-');
my $future_date         = DateTime->today->add(years => 2)->mdy('-');
my $past_date           = '03-03-1979';
my $distant_past_date   = '03-03-1879';

# 2..7
# to_datetime
{
    my %profile = (
        required                => [qw(good bad realbad unreal)],
        constraint_methods      => {
            good    => to_datetime($format),
            unreal  => to_datetime($format),
            bad     => to_datetime($format),
            realbad => to_datetime($format),
        }, 
        untaint_all_constraints => 1,
    );
    my %data = (
        good    => $good_date,
        unreal  => $unreal_date,
        bad     => $bad_date,
        realbad => $real_bad_date,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    ok( $results->invalid('realbad'), 'datetime expected invalid');
    ok( $results->invalid('unreal'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $good_date, 'DateTime stringifies correctly');
}


# 8..17
# ymd_to_datetime
{
    my %profile = (
        required                => [qw(my_year)],
        constraint_methods      => {
            my_year => ymd_to_datetime(qw(my_year my_month my_day)),
        },
        untaint_all_constraints => 1,
    );
    my %data = (
        my_year     => 2005,
        my_month    => 2,
        my_day      => 17,
    );
    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('my_year'), 'ymd_to_datetime: correct');
    isa_ok( $results->valid('my_year'), 'DateTime');

    # now with hms
    $profile{constraint_methods}->{my_year} = 
        ymd_to_datetime(qw(my_year my_month my_day my_hour my_min my_sec));
    $data{my_hour} = 14;
    $data{my_min}  = 6;
    $data{my_sec}  = 14;

    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('my_year'), 'ymd_to_datetime: correct');
    isa_ok( $results->valid('my_year'), 'DateTime');

    # make sure it fails if the month is not a number
    $data{my_month} = "";
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_year'), 'ymd_to_datetime: invalid date');
    $data{my_month} = undef;
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_year'), 'ymd_to_datetime: invalid date');
    $data{my_month} = 2;    # reset the month

    # make sure it fails if the day is not a number
    $data{my_day} = "";
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_year'), 'ymd_to_datetime: invalid date');
    $data{my_day} = undef;
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_year'), 'ymd_to_datetime: invalid date');
    $data{my_day} = "17";   # reset the day

    # make sure it fails the year is not a number
    $profile{constraint_methods} = {
        'my_month'  => ymd_to_datetime(qw(my_year my_month my_day my_hour my_min my_sec)),
    };
    $profile{required} = ['my_month'];
    $data{my_year} = "";
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_month'), 'ymd_to_datetime: invalid date');
    $data{my_year} = undef;
    $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->invalid('my_month'), 'ymd_to_datetime: invalid date');
}

# 18..22
# before_today
{
    my %data = (
        good    => $past_date,
        bad     => $future_date,
        today   => $today,
    );
    my %profile = (
        required                => [qw(good bad today)],
        constraint_methods      => {
            good    => before_today($format),
            bad     => before_today($format),
            today   => before_today($format),
        },
        untaint_all_constraints => 1,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->valid('today'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $past_date, 'DateTime stringifies correctly');
}

# 23..27
# after_today
{
    my %data = (
        good    => $future_date,
        bad     => $past_date,
        today   => $today,
    );
    my %profile = (
        required                => [qw(good bad today)],
        constraint_methods      => {
            good    => after_today($format),
            bad     => after_today($format),
            today   => after_today($format),
        },
        untaint_all_constraints => 1,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->valid('today'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $future_date, 'DateTime stringifies correctly');
}

# 28..31
# ymd_before_today
{
    # split it up into ymd
    my @good_parts = split(/-/, $past_date);
    my @bad_parts = split(/-/, $future_date);
    my @today_parts = split(/-/, $today);

    my %data = (
        good_m  => $good_parts[0],
        good_d  => $good_parts[1],
        good_y  => $good_parts[2],
        bad_m   => $bad_parts[0],
        bad_d   => $bad_parts[1],
        bad_y   => $bad_parts[2],
        today_m => $today_parts[0],
        today_d => $today_parts[1],
        today_y => $today_parts[2],
    );
    my %profile = (
        required                => [qw(good_y bad_y today_y)],
        untaint_all_constraints => 1,
        constraint_methods      => {
            good_y   => ymd_before_today(qw(good_y  good_m  good_d)),
            bad_y    => ymd_before_today(qw(bad_y   bad_m   bad_d)),
            today_y  => ymd_before_today(qw(today_y today_m today_d)),
        },
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good_y'), 'datetime expected valid');
    ok( $results->invalid('bad_y'), 'datetime expected invalid');
    ok( $results->valid('today_y'), 'datetime expected valid');
    my $date = $results->valid('good_y');
    isa_ok( $date, 'DateTime');
}

# 32..35
# ymd_after_today
{
    # split it up into ymd
    my @good_parts = split(/-/, $future_date);
    my @bad_parts = split(/-/, $past_date);
    my @today_parts = split(/-/, $today);

    my %data = (
        good_m  => $good_parts[0],
        good_d  => $good_parts[1],
        good_y  => $good_parts[2],
        bad_m   => $bad_parts[0],
        bad_d   => $bad_parts[1],
        bad_y   => $bad_parts[2],
        today_m => $today_parts[0],
        today_d => $today_parts[1],
        today_y => $today_parts[2],
    );
    my %profile = (
        required                => [qw(good_y bad_y today_y)],
        untaint_all_constraints => 1,
        constraint_methods      => {
            good_y   => ymd_after_today(qw(good_y  good_m  good_d)),
            bad_y    => ymd_after_today(qw(bad_y   bad_m   bad_d)),
            today_y  => ymd_after_today(qw(today_y today_m today_d)),
        },
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good_y'), 'datetime expected valid');
    ok( $results->invalid('bad_y'), 'datetime expected invalid');
    ok( $results->valid('today_y'), 'datetime expected valid');
    my $date = $results->valid('good_y');
    isa_ok( $date, 'DateTime');
}

# 36..43
# before_datetime
{
    my %data = (
        good    => $good_date,
        unreal  => $unreal_date,
        bad     => $bad_date,
        realbad => $real_bad_date,
        future  => $distant_future_date,
    );
    my %profile = (
        required                => [qw(good unreal bad realbad future)],
        constraint_methods      => {
            good    => before_datetime($format, $future_date),
            unreal  => before_datetime($format, $future_date),
            bad     => before_datetime($format, $future_date),
            realbad => before_datetime($format, $future_date),
            future  => before_datetime($format, $future_date),
        },
        untaint_all_constraints => 1,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    ok( $results->invalid('realbad'), 'datetime expected invalid');
    ok( $results->invalid('unreal'), 'datetime expected invalid');
    ok( $results->invalid('future'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $good_date, 'DateTime stringifies correctly');

    # test an invalid past date
    $profile{constraint_methods} = { bad => before_datetime($format, $bad_date) };
    $profile{required} = ['bad'];
    $results = Data::FormValidator->check(\%data, \%profile);
    my @any_valid = $results->valid();
    is(scalar @any_valid, 0, 'no valid data');
}

# 44..51
# after_datetime
{
    my %data = (
        good    => $good_date,
        unreal  => $unreal_date,
        bad     => $bad_date,
        realbad => $real_bad_date,
        past    => $distant_past_date,
    );
    my %profile = (
        required                => [qw(good unreal bad realbad past)],
        constraint_methods      => {
            good    => after_datetime($format, $past_date),
            unreal  => after_datetime($format, $past_date),
            bad     => after_datetime($format, $past_date),
            realbad => after_datetime($format, $past_date),
            past    => after_datetime($format, $past_date),
        },
        untaint_all_constraints => 1,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    ok( $results->invalid('realbad'), 'datetime expected invalid');
    ok( $results->invalid('unreal'), 'datetime expected invalid');
    ok( $results->invalid('past'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $good_date, 'DateTime stringifies correctly');

    # test an invalid future_date
    $profile{constraint_methods} = { bad => after_datetime($format, $bad_date) };
    $profile{required} = ['bad'];
    $results = Data::FormValidator->check(\%data, \%profile);
    my @any_valid = $results->valid();
    is(scalar @any_valid, 0, 'no valid data');
}


# 52..61
# between_datetimes
{
    my %data = (
        good            => $good_date,
        unreal          => $unreal_date,
        bad             => $bad_date,
        realbad         => $real_bad_date,
        outside_past    => $distant_past_date,
        outside_future  => $distant_future_date,
    );
    my %profile = (
        required                => [qw(good unreal bad realbad outside_past outside_future)],
        constraint_methods      => {
            good           => between_datetimes($format, $past_date, $future_date),
            unreal         => between_datetimes($format, $past_date, $future_date),
            bad            => between_datetimes($format, $past_date, $future_date),
            realbad        => between_datetimes($format, $past_date, $future_date),
            outside_past   => between_datetimes($format, $past_date, $future_date),
            outside_future => between_datetimes($format, $past_date, $future_date),
        },
        untaint_all_constraints => 1,
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    ok( $results->invalid('realbad'), 'datetime expected invalid');
    ok( $results->invalid('unreal'), 'datetime expected invalid');
    ok( $results->invalid('outside_past'), 'datetime expected invalid');
    ok( $results->invalid('outside_future'), 'datetime expected invalid');
    my $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $good_date, 'DateTime stringifies correctly');

    # test an invalid past_date
    $profile{constraint_methods} = { bad => between_datetimes($format, $bad_date, $future_date) };
    $profile{required} = ['bad'];
    $results = Data::FormValidator->check(\%data, \%profile);
    my @any_valid = $results->valid();
    is(scalar @any_valid, 0, 'no valid data');

    # test an invalid future_date
    $profile{constraint_methods} = { bad => between_datetimes($format, $past_date, $bad_date) };
    $results = Data::FormValidator->check(\%data, \%profile);
    @any_valid = $results->valid();
    is(scalar @any_valid, 0, 'no valid data');
}

