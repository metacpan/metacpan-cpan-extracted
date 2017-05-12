use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
plan(tests => 113);

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import();
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

# 2..13
# to_datetime
{
    my %profile = (
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'], 
        required                => [qw(good bad realbad unreal)],
        untaint_all_constraints => 1,
    );
    my %data = (
        good    => $good_date,
        unreal  => $unreal_date,
        bad     => $bad_date,
        realbad => $real_bad_date,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'to_datetime', 
            as_method   => $as_method, 
            params      => [\$format],
            inputs      => [keys %data ],
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
};


# 14..33
# ymd_to_datetime
{
    foreach my $as_method (0..1) {
        my %profile = (
            validator_packages      => [qw(Data::FormValidator::Constraints::DateTime)],
            required                => [qw(my_year)],
            untaint_all_constraints => 1,
        );
        my %data = (
            my_year     => 2005,
            my_month    => 2,
            my_day      => 17,
        );
        $profile{constraints} = _make_constraints(
            routine     => 'ymd_to_datetime',
            as_method   => $as_method,
            params      => ($as_method ? [qw(my_year my_month my_day)] : [qw(my_month my_day)]),
            inputs      => ['my_year'],
        );
        my $results = Data::FormValidator->check(\%data, \%profile);
        ok( $results->valid('my_year'), 'ymd_to_datetime: correct');
        isa_ok( $results->valid('my_year'), 'DateTime');
    
        # now with hms
        $profile{constraints} = _make_constraints(
            routine     => 'ymd_to_datetime',
            as_method   => $as_method,
            params      => ($as_method ? 
                            [qw(my_year my_month my_day my_hour my_min my_sec)] 
                            : [qw(my_month my_day my_hour my_min my_sec)]),
            inputs      => ['my_year'],
        );
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
        $profile{constraints} = {
            'my_month'  => {
                ($as_method ? 'constraint_method' : 'constraint') => 'ymd_to_datetime',
                params      => [qw(my_year my_month my_day my_hour my_min my_sec)],
            },
        };
        $profile{required} = ['my_month'];
        $data{my_year} = "";
        $results = Data::FormValidator->check(\%data, \%profile);
        ok( $results->invalid('my_month'), 'ymd_to_datetime: invalid date');
        $data{my_year} = undef;
        $results = Data::FormValidator->check(\%data, \%profile);
        ok( $results->invalid('my_month'), 'ymd_to_datetime: invalid date');
    }
}

# 34..43
# before_today
{
    my %data = (
        good    => $past_date,
        bad     => $future_date,
        today   => $today,
    );
    my %profile = (
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [keys %data],
        untaint_all_constraints => 1,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'before_today',
            as_method   => $as_method,
            params      => [\$format],
            inputs      => [keys %data],
        );
        my $results = Data::FormValidator->check(\%data, \%profile);
        ok( $results->valid('good'), 'datetime expected valid');
        ok( $results->valid('today'), 'datetime expected valid');
        ok( $results->invalid('bad'), 'datetime expected invalid');
        my $date = $results->valid('good');
        isa_ok( $date, 'DateTime');
        is( "$date", $past_date, 'DateTime stringifies correctly');
    }
}

# 44..53
# after_today
{
    my %data = (
        good    => $future_date,
        bad     => $past_date,
        today   => $today,
    );
    my %profile = (
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [keys %data],
        untaint_all_constraints => 1,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'after_today',
            as_method   => $as_method,
            params      => [\$format],
            inputs      => [keys %data],
        );
        my $results = Data::FormValidator->check(\%data, \%profile);
        ok( $results->valid('good'), 'datetime expected valid');
        ok( $results->valid('today'), 'datetime expected valid');
        ok( $results->invalid('bad'), 'datetime expected invalid');
        my $date = $results->valid('good');
        isa_ok( $date, 'DateTime');
        is( "$date", $future_date, 'DateTime stringifies correctly');
    }
}

# 54..57
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
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [qw(good_y bad_y today_y)],
        untaint_all_constraints => 1,
        constraints             => {
            good_y   => {
                constraint_method => 'ymd_before_today',
                params            => [qw(good_y good_m good_d)],
            },
            bad_y    => {
                constraint_method => 'ymd_before_today',
                params            => [qw(bad_y bad_m bad_d)],
            },
            today_y  => {
                constraint_method => 'ymd_before_today',
                params            => [qw(today_y today_m today_d)],
            },
        },
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good_y'), 'datetime expected valid');
    ok( $results->invalid('bad_y'), 'datetime expected invalid');
    ok( $results->valid('today_y'), 'datetime expected valid');
    my $date = $results->valid('good_y');
    isa_ok( $date, 'DateTime');
}

# 58..61
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
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [qw(good_y bad_y today_y)],
        untaint_all_constraints => 1,
        constraints             => {
            good_y   => {
                constraint_method => 'ymd_after_today',
                params            => [qw(good_y good_m good_d)],
            },
            bad_y    => {
                constraint_method => 'ymd_after_today',
                params            => [qw(bad_y bad_m bad_d)],
            },
            today_y  => {
                constraint_method => 'ymd_after_today',
                params            => [qw(today_y today_m today_d)],
            },
        },
    );

    my $results = Data::FormValidator->check(\%data, \%profile);
    ok( $results->valid('good_y'), 'datetime expected valid');
    ok( $results->invalid('bad_y'), 'datetime expected invalid');
    ok( $results->valid('today_y'), 'datetime expected valid');
    my $date = $results->valid('good_y');
    isa_ok( $date, 'DateTime');
}

# 62..77
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
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [keys %data],
        untaint_all_constraints => 1,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'before_datetime',
            as_method   => $as_method,
            params      => [\$format, \$future_date],
            inputs      => [keys %data],
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

        # test an invalid future_date
        $profile{constraints} = _make_constraints(
            routine     => 'before_datetime',
            as_method   => $as_method,
            params      => [\$format, \$bad_date],
            inputs      => [keys %data],
        );
        $results = Data::FormValidator->check(\%data, \%profile);
        my @any_valid = $results->valid();
        is(scalar @any_valid, 0, 'no valid data');
    }
}

# 78..93
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
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [keys %data],
        untaint_all_constraints => 1,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'after_datetime',
            as_method   => $as_method,
            params      => [\$format, \$past_date],
            inputs      => [keys %data],
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

        # test an invalid past_date
        $profile{constraints} = _make_constraints(
            routine     => 'after_datetime',
            as_method   => $as_method,
            params      => [\$format, \$bad_date],
            inputs      => [keys %data],
        );
        $results = Data::FormValidator->check(\%data, \%profile);
        my @any_valid = $results->valid();
        is(scalar @any_valid, 0, 'no valid data');
    }
}


# 94..113
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
        validator_packages      => ['Data::FormValidator::Constraints::DateTime'],
        required                => [keys %data],
        untaint_all_constraints => 1,
    );
    foreach my $as_method (0..1) {
        $profile{constraints} = _make_constraints(
            routine     => 'between_datetimes',
            as_method   => $as_method,
            params      => [\$format, \$past_date, \$future_date],
            inputs      => [keys %data],
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
        $profile{constraints} = _make_constraints(
            routine     => 'between_datetimes',
            as_method   => $as_method,
            params      => [\$format, \$bad_date, \$future_date],
            inputs      => [keys %data],
        );
        $results = Data::FormValidator->check(\%data, \%profile);
        my @any_valid = $results->valid();
        is(scalar @any_valid, 0, 'no valid data');

        # test an invalid future_date
        $profile{constraints} = _make_constraints(
            routine     => 'between_datetimes',
            as_method   => $as_method,
            params      => [\$format, \$past_date, \$bad_date],
            inputs      => [keys %data],
        );
        $results = Data::FormValidator->check(\%data, \%profile);
        @any_valid = $results->valid();
        is(scalar @any_valid, 0, 'no valid data');
    }
}


sub _make_constraints {
    my %args = @_;
    my ($method, $as_method, @params) = @_;
    my %constraints = ();

    foreach my $input (@{$args{inputs}}) {
        if( $args{as_method} ) {
            $constraints{$input} = {
                constraint_method   => $args{routine},
                params              => $args{params},
            };
        } else {
            my @tmp_params = @{$args{params}};
            $constraints{$input} = {
                constraint  => $args{routine},
                params      => [$input, @tmp_params],
            };
        }
    }
    return \%constraints;
};
