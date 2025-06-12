# NAME

Date::Holidays::AU - Determine Australian Public Holidays

# VERSION

Version 0.35

# SYNOPSIS

    use Date::Holidays::AU qw( is_holiday );
    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;
    my $state = 'VIC';
    print "Excellent\n" if is_holiday( $year, $month, $day, $state );

# DESCRIPTION

This module makes an attempt at describing Australian holidays using the
interface defined [Date::Holidays::Abstract](https://metacpan.org/pod/Date::Holidays::Abstract), which defines two methods,
is\_holiday and holidays.

# SUBROUTINES/METHODS

- is\_holiday($year, $month, $day, $state, $params)

    returns true or false depending to whether or not the date in question
    is a holiday according to the state and the additional parameters.

- holidays(year => $year, state => $state, %params)

    Returns a hashref of all defined holidays in the year according
    to the state and the additional parameters. Keys in the hashref
    are in 'mmdd' format, the values are the names of the
    holidays.

    The states must be one of the allowed [ISO 3166-2:AU](https://en.wikipedia.org/wiki/ISO_3166-2:AU) codes; 'VIC','WA','NT','QLD','TAS','NSW','SA' or 'ACT'.  The
    default state is 'VIC'.  The following tables lists the allowable parameters
    for each state;

        State  Parameter             Default   Values
        VIC    no_melbourne_cup      0         1 | 0
        NT     region                'Darwin'  'Alice Springs' | 'Tennant Creek' | 'Katherine' | 'Darwin' | 'Borrolooda'
        QLD    no_show_day           0         1 | 0
        NSW    include_bank_holiday  0         1 | 0
        ACT    include_bank_holiday  0         1 | 0
        TAS    holidays              []        'Devonport Cup','King Island Show','Launceston Cup','Hobart Show','Recreation Day','Burnie Show','Agfest','Launceston Show','Flinders Island Show'

# DEPENDENCIES

Uses **Date::Easter** for easter calculations. Makes use of the **Time::Local**
modules from the standard Perl distribution.

# CONFIGURATION AND ENVIRONMENT

Date::Holidays::AU requires no configuration files or environment variables.  

# INCOMPATIBILITIES

None reported

# AUTHOR

David Dick <ddick@cpan.org>

# BUGS AND LIMITATIONS

Support for WA's Queen's Birthday holiday only consists of hard-coded values.
Likewise for Grand Final Eve in Victoria.  

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Date::Holidays::Abstract](https://metacpan.org/pod/Date::Holidays::Abstract), [Date::Holiday::DE](https://metacpan.org/pod/Date::Holidays::DE), [Date::Holiday::UK](https://metacpan.org/pod/Date::Holidays::UK)
