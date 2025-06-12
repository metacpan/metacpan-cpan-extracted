package Date::Holidays::AU;

use strict;
use warnings;

use Time::Local();
use Date::Easter();
use Exporter();
use Carp();

use base qw(Exporter);
our @EXPORT_OK = qw(is_holiday holidays);
our $VERSION   = '0.35';

sub _DEFAULT_STATE                        { return 'VIC' }
sub _LOCALTIME_YEAR_IDX                   { return 5 }
sub _LOCALTIME_BASE_YEAR                  { return 1900 }
sub _AUSTRALIA_DAY_IN_JANUARY             { return 26 }
sub _THIRD_DAY_OF_EASTER                  { return 3 }
sub _FOURTH_DAY_OF_EASTER                 { return 4 }
sub _ANZAC_DAY_IN_APRIL                   { return 25 }
sub _CHRISTMAS_DAY_IN_DECEMBER            { return 25 }
sub _APRIL_MONTH_NUMBER                   { return 4 }
sub _MAY_MONTH_NUMBER                     { return 5 }
sub _OCTOBER_MONTH_NUMBER                 { return 10 }
sub _NOVEMBER_MONTH_NUMBER                { return 11 }
sub _DECEMBER_MONTH_NUMBER                { return 12 }
sub _YEAR_OF_QUEEN_ELIZABETHS_DEATH       { return 2022 }
sub _DAYS_IN_JANUARY                      { return 31 }
sub _DAYS_IN_MARCH                        { return 31 }
sub _DAYS_IN_APRIL                        { return 30 }
sub _DAYS_IN_MAY                          { return 31 }
sub _DAYS_IN_JUNE                         { return 30 }
sub _DAYS_IN_JULY                         { return 31 }
sub _DAYS_IN_AUGUST                       { return 31 }
sub _DAYS_IN_SEPTEMBER                    { return 30 }
sub _DAYS_IN_OCTOBER                      { return 31 }
sub _DAYS_IN_NOVEMBER                     { return 30 }
sub _DAYS_IN_DECEMBER                     { return 31 }
sub _THURSDAY                             { return 4 }
sub _FRIDAY                               { return 5 }
sub _SATURDAY                             { return 6 }
sub _STARTING_YEAR_FOR_NSW_ADDITIONAL_DAY { return 2012 }

my %allowed_states = (
    VIC => 1,
    WA  => 1,
    NT  => 1,
    QLD => 1,
    TAS => 1,
    NSW => 1,
    SA  => 1,
    ACT => 1,
);

sub holidays {
    my (%params) = @_;
    if ( ( exists $params{year} ) && ( defined $params{year} ) ) {
    }
    else {
        $params{year} = (localtime)[ _LOCALTIME_YEAR_IDX() ];
        $params{year} += _LOCALTIME_BASE_YEAR();
    }
    if ( $params{year} !~ /^\d{1,4}$/smx ) {
        Carp::croak(
            q[Year must be numeric and from one to four digits, eg '2004']);
    }
    my $year = $params{year};
    if ( !defined $params{state} ) {
        Carp::carp( 'State not defined, setting state to default: '
              . _DEFAULT_STATE() );
        $params{state} = _DEFAULT_STATE();
    }

    my $state = uc $params{state};
    if ( !$allowed_states{$state} ) {
        Carp::croak(
            q[State must be one of 'VIC','WA','NT','QLD','TAS','NSW','SA','ACT']
        );
    }
    my $concat = $state;
    foreach my $key ( sort { $a cmp $b } keys %params ) {
        next if ( $key eq 'year' );
        next if ( $key eq 'state' );
        next if ( !$params{$key} );
        if ( ref $params{$key} ) {
            if ( ( ref $params{$key} ) eq 'ARRAY' ) {
                $concat .= '_' . $key;
                foreach my $element ( @{ $params{$key} } ) {
                    $concat .= '_' . $element;
                }
            }
        }
        else {
            $concat .= '_' . $key . '_' . $params{$key};
        }
        $concat = lc $concat;
        $concat =~ s/\s*//smxg;
    }
    my %holidays;
    if ( $state eq 'TAS' ) {
        if ( exists $params{holidays} ) {
            if (   ( ref $params{holidays} )
                && ( ( ref $params{holidays} ) eq 'ARRAY' ) )
            {
            }
            else {
                Carp::croak(
                    q[Holidays parameter must be a reference to an array]);
            }
        }
        else {
            $params{holidays} = [];
        }
        %holidays = _check_tas_holidays( $params{holidays}, $year, %holidays );
    }
    elsif ( $state eq 'ACT' ) {
        foreach my $holiday ( _compute_canberra_day($year) ) {    # canberra day
            $holidays{$holiday} = 'Canberra Day';
        }
    }
    foreach my $holiday ( _compute( 1, 1, $year, { 'day_in_lieu' => 1 } ) )
    {    # new years day
        if ( $holiday eq '0101' ) {
            $holidays{$holiday} = 'New Years Day';
        }
        else {
            $holidays{$holiday} = 'New Years Day Holiday';
        }
    }
    foreach my $holiday (
        _compute(
            _AUSTRALIA_DAY_IN_JANUARY(),
            1, $year, { 'day_in_lieu' => 1 }
        )
      )
    {    # australia day
        if ( $holiday eq '0126' ) {
            $holidays{$holiday} = 'Australia Day';
        }
        else {
            $holidays{$holiday} = 'Australia Day Holiday';
        }
    }
    if ( $state eq 'VIC' ) {
        foreach my $holiday ( _compute_vic_labour_day($year) )
        {    # VIC labour day
            $holidays{$holiday} = 'Labour Day';
        }
        foreach my $holiday ( _compute_vic_grand_final_eve_day($year) )
        {    # VIC grand final day
            $holidays{$holiday} = 'Grand Final Eve';
        }
    }
    elsif ( $state eq 'QLD' ) {
        foreach my $holiday ( _compute_qld_labour_day($year) )
        {    # QLD labour day
            $holidays{$holiday} = 'Labour Day';
        }
    }
    elsif ( $state eq 'WA' ) {
        foreach my $holiday ( _compute_wa_labour_day($year) ) {  # WA labour day
            $holidays{$holiday} = 'Labour Day';
        }
    }
    elsif ( $state eq 'SA' ) {
        foreach my $holiday ( _compute_sa_adelaide_cup_day($year) )
        {    # adelaide cup day
            $holidays{$holiday} = 'Adelaide Cup Day';
        }
    }
    my %easter_day_name = (
        0                       => 'Good Friday',
        1                       => 'Easter Saturday',
        2                       => 'Easter Sunday',
        _THIRD_DAY_OF_EASTER()  => 'Easter Monday',
        _FOURTH_DAY_OF_EASTER() => 'Easter Tuesday',
    );
    my $count = 0;
    foreach my $holiday ( _compute_easter( $year, $state ) ) {    # easter
        $holidays{$holiday} = $easter_day_name{$count};
        $count += 1;
    }
    if ( ( $state eq 'VIC' ) || ( $state eq 'TAS' ) || ( $state eq 'NSW' ) ) {
        foreach my $holiday (
            _compute( _ANZAC_DAY_IN_APRIL(), _APRIL_MONTH_NUMBER(), $year ) )
        {    # ANZAC day
            $holidays{$holiday} = 'Anzac Day';
        }
    }
    else {
        foreach my $holiday (
            _compute(
                _ANZAC_DAY_IN_APRIL(), _APRIL_MONTH_NUMBER(),
                $year, { 'day_in_lieu' => 1 }
            )
          )
        {    # ANZAC day
            if ( $holiday eq '0425' ) {
                $holidays{$holiday} = 'Anzac Day';
            }
            else {
                $holidays{$holiday} = 'Anzac Day Holiday';
            }
        }
    }
    if ( $state eq 'SA' ) {
        foreach my $holiday ( _compute_sa_volunteers_day($year) )
        {    # SA Volunteers day
            $holidays{$holiday} = 'Volunteers Day';
        }
    }
    elsif ( $state eq 'NT' ) {
        foreach my $holiday ( _compute_nt_may_day($year) ) {    # NT May day
            $holidays{$holiday} = 'May Day';
        }
    }
    elsif ( $state eq 'TAS' ) {
        foreach my $allowed ( @{ $params{holidays} } ) {
            $allowed = lc $allowed;
            $allowed =~ s/\s*//smxg;
            if ( $allowed eq 'agfest' ) {
                foreach my $holiday ( _compute_agfest($year) ) {    # TAS Agfest
                    $holidays{$holiday} = 'Agfest';
                }
            }
        }
    }
    if ( $state eq 'WA' ) {
        foreach my $holiday ( _compute_wa_foundation_day($year) )
        {    # WA Foundation day
            $holidays{$holiday} = 'Foundation Day';
        }
    }
    elsif ( $state eq 'QLD' ) {
    }
    else {
        foreach my $holiday ( _compute_royal_bday($year) )
        {    # King's Birthday day
            if ( $year <= _YEAR_OF_QUEEN_ELIZABETHS_DEATH() ) {
                $holidays{$holiday} = q[Queen's Birthday];
            }
            else {
                $holidays{$holiday} = q[King's Birthday];
            }
        }
    }
    my $holiday_hashref;
    if ( $state eq 'VIC' ) {
        if (   ( exists $params{no_melbourne_cup} )
            && ( $params{no_melbourne_cup} ) )
        {
        }
        else {
            foreach my $holiday ( _compute_melbourne_cup_day($year) )
            {    # Melbourne Cup day
                $holidays{$holiday} = 'Melbourne Cup Day';
            }
        }
    }
    elsif ( $state eq 'QLD' ) {
        if (   ( exists $params{no_show_day} )
            && ( $params{no_show_day} ) )
        {
        }
        else {
            foreach my $holiday ( _compute_qld_show_day($year) )
            {    # Queensland Show day
                $holidays{$holiday} = 'Queensland Show Day';
            }
        }
        foreach my $holiday ( _compute_qld_royal_bday($year) )
        {        # QLD Queens Birthday day
            if ( $year <= _YEAR_OF_QUEEN_ELIZABETHS_DEATH() ) {
                $holidays{$holiday} = q[Queen's Birthday];
            }
            else {
                $holidays{$holiday} = q[King's Birthday];
            }
        }
    }
    elsif ( $state eq 'SA' ) {
        foreach my $holiday ( _compute_nsw_sa_act_labour_day($year) )
        {        # SA labour day
            $holidays{$holiday} = 'Labour Day';
        }
    }
    elsif ( $state eq 'NT' ) {
        foreach
          my $holiday_hashref ( _compute_nt_show_day_hash( $year, \%params ) )
        {        # NT regional show days
            $holidays{ $holiday_hashref->{date} } =
              $holiday_hashref->{name};
        }
        foreach my $holiday ( _compute_nt_picnic_day($year) ) {  # NT picnic day
            $holidays{$holiday} = 'Picnic Day';
        }
    }
    elsif ( $state eq 'WA' ) {
        foreach my $holiday ( _compute_wa_royal_bday($year) )
        {    # WA Queens Birthday day
            if ( $year <= _YEAR_OF_QUEEN_ELIZABETHS_DEATH() ) {
                $holidays{$holiday} = q[Queen's Birthday];
            }
            else {
                $holidays{$holiday} = q[King's Birthday];
            }
        }
    }
    elsif ( $state eq 'ACT' ) {
        if (   ( exists $params{include_bank_holiday} )
            && ( $params{include_bank_holiday} ) )
        {
            foreach my $holiday ( _compute_nsw_act_bank_holiday($year) )
            {    # ACT bank holiday
                $holidays{$holiday} = 'Bank Holiday';
            }
        }
        foreach my $holiday ( _compute_nsw_sa_act_labour_day($year) )
        {        # ACT labour day
            $holidays{$holiday} = 'Labour Day';
        }
    }
    elsif ( $state eq 'TAS' ) {
        foreach my $allowed ( @{ $params{holidays} } ) {
            $allowed = lc $allowed;
            $allowed =~ s/\s*//smxg;
            if ( $allowed eq 'burnieshow' ) {
                foreach my $holiday ( _compute_burnie_show($year) )
                {    # TAS burnie show day
                    $holidays{$holiday} = 'Burnie Show';
                }
            }
            elsif ( $allowed eq 'launcestonshow' ) {
                foreach my $holiday ( _compute_launceston_show($year) )
                {    # TAS launceston show day
                    $holidays{$holiday} = 'Launceston Show';
                }
            }
            elsif ( $allowed eq 'flindersislandshow' ) {
                foreach my $holiday ( _compute_flinders_island_show($year) )
                {    # TAS flinders island show day
                    $holidays{$holiday} = 'Flinders Island Show';
                }
            }
            elsif ( $allowed eq 'hobartshow' ) {
                foreach my $holiday ( _compute_hobart_show($year) )
                {    # TAS hobart show day
                    $holidays{$holiday} = 'Hobart Show';
                }
            }
            elsif ( $allowed eq 'recreationday' ) {
                foreach my $holiday ( _compute_recreation_day($year) )
                {    # TAS recreation day
                    $holidays{$holiday} = 'Recreation Day';
                }
            }
            elsif ( $allowed eq 'devonportshow' ) {
                foreach my $holiday ( _compute_devonport_show($year) )
                {    # TAS devonport show day
                    $holidays{$holiday} = 'Devonport Show';
                }
            }
        }
    }
    else {
        if (   ( exists $params{include_bank_holiday} )
            && ( $params{include_bank_holiday} ) )
        {
            foreach my $holiday ( _compute_nsw_act_bank_holiday($year) )
            {    # NSW bank holiday
                $holidays{$holiday} = 'Bank Holiday';
            }
        }
        foreach my $holiday ( _compute_nsw_sa_act_labour_day($year) )
        {        # NSW labour day
            $holidays{$holiday} = 'Labour Day';
        }
    }
    foreach my $holiday_hashref ( _compute_christmas_hash( $year, $state ) )
    {            # christmas day + boxing day
        $holidays{ $holiday_hashref->{date} } = $holiday_hashref->{name};
    }
    return ( \%holidays );
}

sub _check_tas_holidays {
    my ( $param_holidays, $year, %holidays ) = @_;
    foreach my $allowed ( @{$param_holidays} ) {
        $allowed = lc $allowed;
        $allowed =~ s/\s*//smxg;
        if ( $allowed eq 'devonportcup' ) {
            foreach my $holiday ( _compute_devonport_cup($year) )
            {    # TAS devonport cup
                $holidays{$holiday} = 'Devonport Cup';
            }
        }
    }
    foreach my $allowed ( @{$param_holidays} ) {
        $allowed = lc $allowed;
        $allowed =~ s/\s*//smxg;
        if ( $allowed eq 'devonportcup' ) {
            foreach my $holiday ( _compute_devonport_cup($year) )
            {    # TAS devonport cup
                $holidays{$holiday} = 'Devonport Cup';
            }
        }
        elsif ( $allowed eq 'hobartregatta' ) {
            foreach my $holiday ( _compute_hobart_regatta($year) )
            {    # TAS hobart regatta
                $holidays{$holiday} = 'Hobart Regatta';
            }
        }
        elsif ( $allowed eq 'launcestoncup' ) {
            foreach my $holiday ( _compute_launceston_cup($year) )
            {    # TAS launceston cup
                $holidays{$holiday} = 'Launceston Cup';
            }
        }
        elsif ( $allowed eq 'kingislandshow' ) {
            foreach my $holiday ( _compute_king_island_show($year) )
            {    # TAS king island show
                $holidays{$holiday} = 'King Island Show';
            }
        }
    }
    foreach my $holiday ( _compute_eight_hours_day($year) )
    {    # TAS eight hours day
        $holidays{$holiday} = 'Eight Hours Day';
    }
    return %holidays;
}

sub is_holiday {
    my ( $year, $month, $day, $state, $params ) = @_;
    if ( !defined $state ) {
        $state = _DEFAULT_STATE();
    }
    my $concat = $state;
    foreach my $key ( sort { $a cmp $b } keys %{$params} ) {
        next if ( !$params->{$key} );
        if ( ref $params->{$key} ) {
            if ( ( ref $params->{$key} ) eq 'ARRAY' ) {
                $concat .= '_' . $key;
                foreach my $element ( @{ $params->{$key} } ) {
                    $concat .= '_' . $element;
                }
            }
        }
        else {
            $concat .= '_' . $key . '_' . $params->{$key};
        }
        $concat = lc $concat;
        $concat =~ s/\s*//smxg;
    }
    my $holidays = holidays( 'year' => $year, 'state' => $state, %{$params} );
    my $date     = sprintf '%02d%02d', $month, $day;
    if ( $holidays->{$date} ) {
        return 1;
    }
    else {
        return 0;
    }
}

my @days_in_month = (
    _DAYS_IN_JANUARY(),   0,
    _DAYS_IN_MARCH(),     _DAYS_IN_APRIL(),
    _DAYS_IN_MAY(),       _DAYS_IN_JUNE(),
    _DAYS_IN_JULY(),      _DAYS_IN_AUGUST(),
    _DAYS_IN_SEPTEMBER(), _DAYS_IN_OCTOBER(),
    _DAYS_IN_NOVEMBER(),  _DAYS_IN_DECEMBER(),
);    # feb will be calculated locally

sub _compute_christmas_hash {
    my ( $year, $state ) = @_;
    my $day   = _CHRISTMAS_DAY_IN_DECEMBER();
    my $month = _DECEMBER_MONTH_NUMBER();
    my $date  = Time::Local::timelocal( 0, 0, 0, $day, ( $month - 1 ), $year );
    my ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
      localtime $date;
    my $boxing_day = 'Boxing Day';
    if ( $state eq 'SA' ) {
        $boxing_day = 'Proclamation Day';
    }
    my @holidays;
    push @holidays,
      {
        'name' => 'Christmas Day',
        'date' => sprintf '%02d%02d',
        $month, $day,
      };
    push @holidays,
      {
        'name' => $boxing_day,
        'date' => sprintf '%02d%02d',
        $month, ( $day + 1 ),
      };
    if ( $wday == _FRIDAY() ) {    # Christmas is on a Friday
        push @holidays,
          {
            'name' => "$boxing_day Holiday",
            'date' => sprintf '%02d%02d',
            $month, ( $day + 2 ),
          };
        if (   ( $state eq 'NSW' )
            && ( $year >= _STARTING_YEAR_FOR_NSW_ADDITIONAL_DAY() ) )
        {
            push @holidays,
              {
                'name' => 'Additional Day',
                'date' => sprintf '%02d%02d',
                $month, ( $day + 3 ),
              };
        }
    }
    elsif ( $wday == _SATURDAY() ) {    # Christmas is on a Saturday
        push @holidays,
          {
            'name' => 'Christmas Day Holiday',
            'date' => sprintf '%02d%02d',
            $month, ( $day + 2 ),
          };
        push @holidays,
          {
            'name' => "$boxing_day Holiday",
            'date' => sprintf '%02d%02d',
            $month, ( $day + 3 ),
          };
        if (   ( $state eq 'NSW' )
            && ( $year >= _STARTING_YEAR_FOR_NSW_ADDITIONAL_DAY() ) )
        {
            push @holidays,
              {
                'name' => 'Additional Day',
                'date' => sprintf '%02d%02d',
                $month, ( $day + 4 ),
              };
        }
    }
    elsif ( $wday == 0 ) {    # Christmas is on a Sunday
        push @holidays,
          {
            'name' => 'Christmas Day Holiday',
            'date' => sprintf '%02d%02d',
            $month, ( $day + 2 ),
          };
        if (   ( $state eq 'NSW' )
            && ( $year >= _STARTING_YEAR_FOR_NSW_ADDITIONAL_DAY() ) )
        {
            push @holidays,
              {
                'name' => 'Additional Day',
                'date' => sprintf '%02d%02d',
                $month, ( $day + 3 ),
              };
        }
    }
    return @holidays;
}

sub _compute_nt_show_day_hash {
    my ( $year, $params ) = @_;
    my %nt_show_day = (
        alicesprings =>
          { name => 'Alice Springs Show Day', month => 6, num_fridays => 1 },
        tennantcreek =>
          { name => 'Tennant Creek Show Day', month => 6, num_fridays => 2 },
        katherine =>
          { name => 'Katherine Show Day', month => 6, num_fridays => 3 },
        darwin => { name => 'Darwin Show Day', month => 6, num_fridays => 4 },
        borroloola =>
          { name => 'Borrolooda Show Day', month => 7, num_fridays => 4 },
    );
    my ( $month, $num_fridays, $name );
    if ( ( exists $params->{region} ) && ( defined $params->{region} ) ) {
        my $region = lc $params->{region};
        $region =~ s/\s*//smxg;
        if ( $nt_show_day{$region} ) {
            $name        = $nt_show_day{$region}{name};
            $month       = $nt_show_day{$region}{month};
            $num_fridays = $nt_show_day{$region}{num_fridays};
        }
        else {
            Carp::croak('Unknown region');
        }
    }
    else {
        $name        = $nt_show_day{darwin}{name};
        $month       = $nt_show_day{darwin}{month};
        $num_fridays = $nt_show_day{darwin}{num_fridays};
    }
    my $day     = 1;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $fridays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $fridays < $num_fridays ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == _FRIDAY() ) {
            $fridays += 1;
        }
        if ( $fridays < $num_fridays ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    my @holidays = (
        {
            name => $name,
            date => sprintf '%02d%02d',
            ( $month + 1 ), $day,
        }
    );
    return @holidays;
}

sub _compute_qld_show_day
{ # second wednesday in august, except when there are five wednesdays in august when it is the third wednesday
    my ($year)     = @_;
    my $day        = 1;
    my $month      = 7;
    my $date       = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $wednesdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    my $num_wednesdays;
    ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
      localtime $date;

    if ( ( $wday >= 1 ) && ( $wday <= 3 ) ) {
        $num_wednesdays = 3;
    }
    else {
        $num_wednesdays = 2;
    }
    while ( $wednesdays < $num_wednesdays ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 3 ) {
            $wednesdays += 1;
        }
        if ( $wednesdays < $num_wednesdays ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_devonport_show
{ # friday nearest last day in november, but not later than first day in december
    my ($year) = @_;
    my $month  = _NOVEMBER_MONTH_NUMBER() - 1;
    my $day    = $days_in_month[$month];
    my $date   = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
      localtime $date;
    if ( $wday == _THURSDAY() ) {    # thursday
        $day   = 1;
        $month = _NOVEMBER_MONTH_NUMBER();
    }
    else {
        my %adjustment = ( 0 => 2, 1 => 3, 2 => 4, 3 => 5, 5 => 0, 6 => 1 );
        $day -= $adjustment{$wday};
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_devonport_cup
{  # wednesday not earlier than fifth and not later than the eleventh of January
    my ($year) = @_;
    my $day    = _FRIDAY();
    my $month  = 0;
    my $date   = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
      localtime $date;
    while ( $wday != 3 ) {
        $day += 1;
        $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_launceston_cup {    # last wednesday in feb
    my ($year) = @_;
    my $month  = 1;
    my $day    = 28;

    if ( $year % 4 ) {
    }
    else {
        if ( $year % 100 ) {
            $day = 29;
        }
        else {
            if ( $year % 400 ) {
            }
            else {
                $day = 29;
            }
        }
    }
    my $date       = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $wednesdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $wednesdays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 3 ) {
            $wednesdays += 1;
        }
        if ( $wednesdays < 1 ) {
            $day -= 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_eight_hours_day {    # second monday in march
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 2;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_king_island_show {    # first tuesday in march
    my ($year)   = @_;
    my $day      = 1;
    my $month    = 2;
    my $date     = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $tuesdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $tuesdays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 2 ) {
            $tuesdays += 1;
        }
        if ( $tuesdays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_hobart_regatta {    # second monday in feb
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 1;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_canberra_day {    # third monday in march
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 2;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 3 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 3 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_recreation_day {    # first monday in november
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 10;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_melbourne_cup_day {    # first tuesday in november
    my ($year)   = @_;
    my $day      = 1;
    my $month    = 10;
    my $date     = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $tuesdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $tuesdays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 2 ) {
            $tuesdays += 1;
        }
        if ( $tuesdays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_wa_foundation_day {    # first monday in june
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 5;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_qld_royal_bday {    # first monday in october
    my ($year)  = @_;
    my $day     = 1;
    my $month   = _OCTOBER_MONTH_NUMBER() - 1;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_royal_bday {    # second monday in june
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 5;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_sa_volunteers_day {    # third monday in may up excluding 2006
    my ($year) = @_;
    if ( $year == 2006 ) {
        return ();
    }
    my $day     = 1;
    my $month   = 4;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 3 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 3 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_sa_adelaide_cup_day {    # second monday in march in 2006
    my ($year) = @_;
    if ( $year != 2006 ) {
        return ();
    }
    my $day     = 1;
    my $month   = 2;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_vic_labour_day {    # second monday in march
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 2;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_qld_labour_day {    # first monday in may
    my ($year)     = @_;
    my $day        = 1;
    my $month      = _MAY_MONTH_NUMBER() - 1;
    my $date       = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays    = 0;
    my $which_week = 1;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < $which_week ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < $which_week ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_vic_grand_final_eve_day {    # i have no words ...
    my ($year) = @_;
    my ( $day, $month );
    my %grand_final_eve_day = (
        2015 => { day => 2,  month => 9 },
        2016 => { day => 30, month => 8 },
        2017 => { day => 29, month => 8 },
        2018 => { day => 28, month => 8 },
        2019 => { day => 27, month => 8 },
        2020 => { day => 23, month => 9 },    # Technically "Thank you" day.
        2021 => { day => 24, month => 8 },
        2022 => { day => 23, month => 8 },
        2023 => { day => 29, month => 8 },
        2024 => { day => 27, month => 8 },
        2025 => { day => 26, month => 8 },
    );
    if ( $year < 2015 ) {
        return ();
    }
    elsif ( $grand_final_eve_day{$year} ) {
        $day   = $grand_final_eve_day{$year}{day};
        $month = $grand_final_eve_day{$year}{month};
    }
    else {
        Carp::croak(
q[Don't know how to calculate Grand Final Eve Day in VIC for this year]
        );
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_wa_labour_day {    # first monday in march
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 2;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_nt_may_day {    # first monday in may
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 4;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_agfest {    # friday following first thursday in may
    my ($year)    = @_;
    my $day       = 1;
    my $month     = 4;
    my $date      = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $thursdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $thursdays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 4 ) {
            $thursdays += 1;
        }
        if ( $thursdays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), ( $day + 1 ) );
}

sub _compute_burnie_show {    # friday preceding first saturday in october
    my ($year)    = @_;
    my $day       = 1;
    my $month     = 9;
    my $date      = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $saturdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $saturdays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 6 ) {
            $saturdays += 1;
        }
        if ( $saturdays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    if ( $day == 1 ) {
        return ( sprintf '%02d%02d', $month, $days_in_month[ $month - 1 ] );
    }
    else {
        return ( sprintf '%02d%02d', ( $month + 1 ), ( $day - 1 ) );
    }
}

sub _compute_launceston_show {   # thursday preceding second saturday in october
    my ($year)    = @_;
    my $day       = 1;
    my $month     = 9;
    my $date      = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $saturdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $saturdays < 2 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 6 ) {
            $saturdays += 1;
        }
        if ( $saturdays < 2 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), ( $day - 2 ) );
}

sub _compute_flinders_island_show { # friday preceding third saturday in october
    my ($year)    = @_;
    my $day       = 1;
    my $month     = 9;
    my $date      = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $saturdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $saturdays < 3 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 6 ) {
            $saturdays += 1;
        }
        if ( $saturdays < 3 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), ( $day - 1 ) );
}

sub _compute_hobart_show {    # thursday preceding fourth saturday in october
    my ($year)    = @_;
    my $day       = 1;
    my $month     = 9;
    my $date      = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $saturdays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $saturdays < 4 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 6 ) {
            $saturdays += 1;
        }
        if ( $saturdays < 4 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), ( $day - 2 ) );
}

sub _compute_nt_picnic_day {    # first monday in august
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 7;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_nsw_act_bank_holiday {    # first monday in august
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 7;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_nsw_sa_act_labour_day {    # first monday in october
    my ($year)  = @_;
    my $day     = 1;
    my $month   = 9;
    my $date    = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
    my $mondays = 0;
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    while ( $mondays < 1 ) {
        ( $sec, $min, $hour, undef, undef, undef, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 1 ) {
            $mondays += 1;
        }
        if ( $mondays < 1 ) {
            $day += 1;
            $date = Time::Local::timelocal( 0, 0, 0, $day, $month, $year );
        }
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_wa_royal_bday
{ # monday closest to 30 september???  Formula unknown. Seems to have a 9 day spread???
    my ($year) = @_;
    my ( $day, $month );
    my %wa_royal_bday = (
        2004 => { day => 4,  month => 9 },
        2005 => { day => 26, month => 8 },
        2006 => { day => 2,  month => 9 },
        2007 => { day => 1,  month => 9 },
        2008 => { day => 29, month => 8 },
        2009 => { day => 28, month => 8 },
        2010 => { day => 27, month => 8 },
        2011 => { day => 28, month => 8 },
        2012 => { day => 1,  month => 9 },
        2013 => { day => 30, month => 8 },
        2014 => { day => 29, month => 8 },
        2015 => { day => 28, month => 8 },
        2016 => { day => 26, month => 8 },
        2017 => { day => 25, month => 8 },
        2018 => { day => 24, month => 8 },
        2019 => { day => 30, month => 8 },
        2020 => { day => 28, month => 8 },
        2021 => { day => 27, month => 8 },
        2022 => { day => 26, month => 8 },
        2023 => { day => 25, month => 8 },
        2024 => { day => 23, month => 8 },
        2025 => { day => 29, month => 8 },
        2026 => { day => 28, month => 8 },
        2027 => { day => 27, month => 8 },
    );
    if ( $wa_royal_bday{$year} ) {
        $day   = $wa_royal_bday{$year}{day};
        $month = $wa_royal_bday{$year}{month};
    }
    elsif ( $year <= _YEAR_OF_QUEEN_ELIZABETHS_DEATH() ) {
        Carp::croak(
            q[Don't know how to calculate Queen's Birthday in WA for this year]
        );
    }
    else {
        Carp::croak(
            q[Don't know how to calculate King's Birthday in WA for this year]);
    }
    return ( sprintf '%02d%02d', ( $month + 1 ), $day );
}

sub _compute_easter {
    my ( $year,  $state ) = @_;
    my ( $month, $day )   = Date::Easter::gregorian_easter($year);
    my $date = Time::Local::timelocal( 0, 0, 0, $day, ( $month - 1 ), $year );
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    ( $sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst ) =
      localtime $date;
    my @holidays;

    # good friday + easter saturday
    if ( $month == 2 ) {    # march
        push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day - 2 );
        push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day - 1 );
    }
    else {                  # april
        if ( $day == 2 ) {
            push @holidays,
              sprintf '%02d%02d', $month, $days_in_month[ $month - 1 ];
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), 1;
        }
        elsif ( $day == 1 ) {
            push @holidays,
              sprintf '%02d%02d', $month, ( $days_in_month[ $month - 1 ] - 1 );
            push @holidays,
              sprintf '%02d%02d', $month, ( $days_in_month[ $month - 1 ] );
        }
        else {
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day - 2 );
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day - 1 );
        }
    }

    # easter sunday
    push @holidays, sprintf '%02d%02d', ( $month + 1 ), $day;

    # easter monday
    if ( $month == 2 ) {    # march
        if ( $day == $days_in_month[$month] ) {
            push @holidays, sprintf '%02d%02d', ( $month + 2 ), 1;
        }
        else {
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day + 1 );
        }
    }
    else {
        push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day + 1 );
    }
    if ( $state eq 'TAS' ) {
        if ( $month == 2 ) {    # march
            if ( $day == $days_in_month[$month] ) {
                push @holidays, sprintf '%02d%02d', ( $month + 2 ), 2;
            }
            elsif ( ( $day + 1 ) == $days_in_month[$month] ) {
                push @holidays, sprintf '%02d%02d', ( $month + 2 ), 1;
            }
            else {
                push @holidays,
                  sprintf '%02d%02d', ( $month + 1 ), ( $day + 2 );
            }
        }
        else {
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), ( $day + 1 );
        }
    }
    return @holidays;
}

sub _compute {
    my ( $day, $month, $year, $params ) = @_;
    my $date = Time::Local::timelocal( 0, 0, 0, $day, ( $month - 1 ), $year );
    my ( $sec, $min, $hour, $wday, $yday, $isdst );
    my @holidays;
    push @holidays, sprintf '%02d%02d', $month, $day;
    if ( $params->{day_in_lieu} ) {
        ( $sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst ) =
          localtime $date;
        if ( $wday == 0 ) {
            $day += 1;
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), $day;
        }
        elsif ( $wday == 6 ) {
            $day += 2;
            push @holidays, sprintf '%02d%02d', ( $month + 1 ), $day;
        }
    }
    return (@holidays);
}

1;

__END__

=head1 NAME

Date::Holidays::AU - Determine Australian Public Holidays

=head1 VERSION
 
Version 0.35

=head1 SYNOPSIS

  use Date::Holidays::AU qw( is_holiday );
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  my $state = 'VIC';
  print "Excellent\n" if is_holiday( $year, $month, $day, $state );

=head1 DESCRIPTION

This module makes an attempt at describing Australian holidays using the
interface defined L<Date::Holidays::Abstract|Date::Holidays::Abstract>, which defines two methods,
is_holiday and holidays.

=head1 SUBROUTINES/METHODS

=over

=item is_holiday($year, $month, $day, $state, $params)

returns true or false depending to whether or not the date in question
is a holiday according to the state and the additional parameters.

=item holidays(year => $year, state => $state, %params)

Returns a hash reference of all defined holidays in the year according
to the state and the additional parameters. Keys in the hash reference
are in 'mm/dd' format, the values are the names of the
holidays.

The states must be one of the allowed L<ISO 3166-2:AU|https://en.wikipedia.org/wiki/ISO_3166-2:AU> codes; 'VIC','WA','NT','QLD','TAS','NSW','SA' or 'ACT'.  The
default state is 'VIC'.  The following tables lists the allowable parameters
for each state;

   State  Parameter             Default   Values
   VIC    no_melbourne_cup	0         1 | 0
   NT     region		'Darwin'  'Alice Springs' | 'Tennant Creek' | 'Katherine' | 'Darwin' | 'Borrolooda'
   QLD    no_show_day		0         1 | 0
   NSW    include_bank_holiday	0         1 | 0
   ACT    include_bank_holiday	0         1 | 0
   TAS    holidays              []        'Devonport Cup','King Island Show','Launceston Cup','Hobart Show','Recreation Day','Burnie Show','Agfest','Launceston Show','Flinders Island Show'

=back

=head1 DEPENDENCIES

Uses B<Date::Easter> for Easter calculations. Makes use of the B<Time::Local>
modules from the standard Perl distribution.

=head1 CONFIGURATION AND ENVIRONMENT
 
Date::Holidays::AU requires no configuration files or environment variables.  

=head1 INCOMPATIBILITIES
 
None reported

=head1 AUTHOR

David Dick <ddick@cpan.org>

=head1 BUGS AND LIMITATIONS

Support for WA's Queen's Birthday holiday only consists of hard-coded values.
Likewise for Grand Final Eve in Victoria.  

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Date::Holidays::Abstract|Date::Holidays::Abstract>, L<Date::Holiday::DE|Date::Holidays::DE>, L<Date::Holiday::UK|Date::Holidays::UK>

=cut

