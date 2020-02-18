package Date::Holidays::GB;

our $VERSION = '0.016';

# ABSTRACT: Determine British holidays - Current UK public and bank holiday dates up to 2021

use strict;
use warnings;
use utf8;

use DateTime;

use base qw( Date::Holidays::Super Exporter );
our @EXPORT_OK = qw(
  holidays
  gb_holidays
  holidays_ymd
  is_holiday
  is_gb_holiday
  next_holiday
);

# See
# http://en.wikipedia.org/wiki/ISO_3166-2
# http://en.wikipedia.org/wiki/ISO_3166-2:GB

use constant REGION_NAMES => {
    EAW => 'England & Wales',
    SCT => 'Scotland',
    NIR => 'Northern Ireland',
};
use constant REGIONS => [ sort keys %{ +REGION_NAMES } ];

our %holidays;
set_holidays(\*DATA);

sub set_holidays {
    my $fh = shift;
    while (<$fh>) {
        chomp;
        my ( $date, $region, $name ) = split /\t/;
        next unless $date && $region && $name;

        my ( $y, $m, $d ) = split /-/, $date;
        $holidays{$y}->{$date}->{$region} = $name;
    }

    # Define an 'all' if all three regions have a holiday on this day, taking
    # EAW name as the canonical name
    while ( my ( $year, $dates ) = each %holidays ) {
        foreach my $holiday ( values %{$dates} ) {
            $holiday->{all} = $holiday->{EAW}
                if keys %{$holiday} == @{ +REGIONS };
        }
    }
}

sub gb_holidays { return holidays(@_) }

sub holidays {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], regions => $_[1] );

    unless ( exists $args{year} && defined $args{year} ) {
        $args{year} = ( localtime(time) )[5];
        $args{year} += 1900;
    }

    unless ( $args{year} =~ /^\d{4}$/ ) {
        die "Year must be numeric and four digits, eg '2004'";
    }

    # return if empty regions list (undef gets full list)
    my @region_codes = @{ $args{regions} || REGIONS }
        or return {};

    my %return;

    while ( my ( $date, $holiday ) = each %{ $holidays{ $args{year} } } ) {
        my $string = _holiday( $holiday, \@region_codes )
            or next;

        if ( $args{ymd} ) {
            $return{$date} = $string;
        }
        else {
            my ( undef, $m, undef, $d ) = unpack( 'A5A2A1A2', $date );
            $return{ $m . $d } = $string;
        }
    }

    return \%return;
}

sub holidays_ymd {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], regions => $_[1] );

    return holidays( %args, ymd => 1 );
}

sub is_gb_holiday { return is_holiday(@_) }

sub is_holiday {
    my %args
        = $_[0] =~ m/[^0-9-]/
        ? @_
        : ( year => $_[0], month => $_[1], day => $_[2], regions => $_[3] );

    my ( $y, $m, $d );

    if ( $args{date} ) {
        ( $y, $m, $d ) = $args{date} =~ m{^([0-9]{4})-([0-9]{2})-([0-9]{2})$};
    }
    else {
        ( $y, $m, $d ) = @args{qw/ year month day /};
    }

    die "Must specify either 'date' or 'year', 'month' and 'day'"
        unless $y && $m && $d;

    my $date = sprintf( "%04d-%02d-%02d", $y, $m, $d );

    # return if empty regions list (undef gets full list)
    my @region_codes = @{ $args{regions} || REGIONS }
        or return;

    # return if no region has holiday
    my $holiday = $holidays{$y}->{$date}
        or return;

    return _holiday( $holiday, \@region_codes );
}

sub next_holiday {
    my @regions = @_;

    unless (@regions) {
        @regions = ( 'all', @{ +REGIONS } );
    }

    my $now   = DateTime->now->set_time_zone("Europe/London");
    my $year  = $now->year;
    my $today = $now->ymd;

    my %next_holidays;

    foreach my $date ( sort keys %{ $holidays{$year} } ) {
        next unless $date gt $today;

        my $holiday = $holidays{$year}->{$date};

        foreach my $region (@regions) {
            my $name = $holiday->{$region} or next;

            $next_holidays{$region} ||= { name => $name, date => $date };
        }

        last if $next_holidays{all} or keys %next_holidays == @{ +REGIONS };
    }

    return \%next_holidays;
}

sub _holiday {
    my ( $holiday, $region_codes ) = @_;

    # return canonical name (EAW) if all regions have holiday
    return $holiday->{all} if $holiday->{all};

    my %region_codes = map { $_ => 1 } @{$region_codes};

    # return comma separated string of holidays with region(s) in
    # parentheses
    my %names;
    foreach my $region ( sort keys %region_codes ) {
        next unless $holiday->{$region};

        push @{ $names{ $holiday->{$region} } }, REGION_NAMES->{$region};
    }

    return unless %names;

    my @strings;
    foreach my $name ( sort keys %names ) {
        push @strings, "$name (" . join( ', ', @{ $names{$name} } ) . ")";
    }

    return join( ', ', @strings );
}

sub date_generated { '2020-02-11' }

1;

__DATA__
2012-01-02	EAW	New Year’s Day
2012-01-02	NIR	New Year’s Day
2012-01-02	SCT	2nd January
2012-01-03	SCT	New Year’s Day
2012-03-19	NIR	St Patrick’s Day
2012-04-06	EAW	Good Friday
2012-04-06	NIR	Good Friday
2012-04-06	SCT	Good Friday
2012-04-09	EAW	Easter Monday
2012-04-09	NIR	Easter Monday
2012-05-07	EAW	Early May bank holiday
2012-05-07	NIR	Early May bank holiday
2012-05-07	SCT	Early May bank holiday
2012-06-04	EAW	Spring bank holiday
2012-06-04	NIR	Spring bank holiday
2012-06-04	SCT	Spring bank holiday
2012-06-05	EAW	Queen’s Diamond Jubilee
2012-06-05	NIR	Queen’s Diamond Jubilee
2012-06-05	SCT	Queen’s Diamond Jubilee
2012-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2012-08-06	SCT	Summer bank holiday
2012-08-27	EAW	Summer bank holiday
2012-08-27	NIR	Summer bank holiday
2012-11-30	SCT	St Andrew’s Day
2012-12-25	EAW	Christmas Day
2012-12-25	NIR	Christmas Day
2012-12-25	SCT	Christmas Day
2012-12-26	EAW	Boxing Day
2012-12-26	NIR	Boxing Day
2012-12-26	SCT	Boxing Day
2013-01-01	EAW	New Year’s Day
2013-01-01	NIR	New Year’s Day
2013-01-01	SCT	New Year’s Day
2013-01-02	SCT	2nd January
2013-03-18	NIR	St Patrick’s Day
2013-03-29	EAW	Good Friday
2013-03-29	NIR	Good Friday
2013-03-29	SCT	Good Friday
2013-04-01	EAW	Easter Monday
2013-04-01	NIR	Easter Monday
2013-05-06	EAW	Early May bank holiday
2013-05-06	NIR	Early May bank holiday
2013-05-06	SCT	Early May bank holiday
2013-05-27	EAW	Spring bank holiday
2013-05-27	NIR	Spring bank holiday
2013-05-27	SCT	Spring bank holiday
2013-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2013-08-05	SCT	Summer bank holiday
2013-08-26	EAW	Summer bank holiday
2013-08-26	NIR	Summer bank holiday
2013-12-02	SCT	St Andrew’s Day
2013-12-25	EAW	Christmas Day
2013-12-25	NIR	Christmas Day
2013-12-25	SCT	Christmas Day
2013-12-26	EAW	Boxing Day
2013-12-26	NIR	Boxing Day
2013-12-26	SCT	Boxing Day
2014-01-01	EAW	New Year’s Day
2014-01-01	NIR	New Year’s Day
2014-01-01	SCT	New Year’s Day
2014-01-02	SCT	2nd January
2014-03-17	NIR	St Patrick’s Day
2014-04-18	EAW	Good Friday
2014-04-18	NIR	Good Friday
2014-04-18	SCT	Good Friday
2014-04-21	EAW	Easter Monday
2014-04-21	NIR	Easter Monday
2014-05-05	EAW	Early May bank holiday
2014-05-05	NIR	Early May bank holiday
2014-05-05	SCT	Early May bank holiday
2014-05-26	EAW	Spring bank holiday
2014-05-26	NIR	Spring bank holiday
2014-05-26	SCT	Spring bank holiday
2014-07-14	NIR	Battle of the Boyne (Orangemen’s Day)
2014-08-04	SCT	Summer bank holiday
2014-08-25	EAW	Summer bank holiday
2014-08-25	NIR	Summer bank holiday
2014-12-01	SCT	St Andrew’s Day
2014-12-25	EAW	Christmas Day
2014-12-25	NIR	Christmas Day
2014-12-25	SCT	Christmas Day
2014-12-26	EAW	Boxing Day
2014-12-26	NIR	Boxing Day
2014-12-26	SCT	Boxing Day
2015-01-01	EAW	New Year’s Day
2015-01-01	NIR	New Year’s Day
2015-01-01	SCT	New Year’s Day
2015-01-02	SCT	2nd January
2015-03-17	NIR	St Patrick’s Day
2015-04-03	EAW	Good Friday
2015-04-03	NIR	Good Friday
2015-04-03	SCT	Good Friday
2015-04-06	EAW	Easter Monday
2015-04-06	NIR	Easter Monday
2015-05-04	EAW	Early May bank holiday
2015-05-04	NIR	Early May bank holiday
2015-05-04	SCT	Early May bank holiday
2015-05-25	EAW	Spring bank holiday
2015-05-25	NIR	Spring bank holiday
2015-05-25	SCT	Spring bank holiday
2015-07-13	NIR	Battle of the Boyne (Orangemen’s Day)
2015-08-03	SCT	Summer bank holiday
2015-08-31	EAW	Summer bank holiday
2015-08-31	NIR	Summer bank holiday
2015-11-30	SCT	St Andrew’s Day
2015-12-25	EAW	Christmas Day
2015-12-25	NIR	Christmas Day
2015-12-25	SCT	Christmas Day
2015-12-28	EAW	Boxing Day
2015-12-28	NIR	Boxing Day
2015-12-28	SCT	Boxing Day
2016-01-01	EAW	New Year’s Day
2016-01-01	NIR	New Year’s Day
2016-01-01	SCT	New Year’s Day
2016-01-04	SCT	2nd January
2016-03-17	NIR	St Patrick’s Day
2016-03-25	EAW	Good Friday
2016-03-25	NIR	Good Friday
2016-03-25	SCT	Good Friday
2016-03-28	EAW	Easter Monday
2016-03-28	NIR	Easter Monday
2016-05-02	EAW	Early May bank holiday
2016-05-02	NIR	Early May bank holiday
2016-05-02	SCT	Early May bank holiday
2016-05-30	EAW	Spring bank holiday
2016-05-30	NIR	Spring bank holiday
2016-05-30	SCT	Spring bank holiday
2016-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2016-08-01	SCT	Summer bank holiday
2016-08-29	EAW	Summer bank holiday
2016-08-29	NIR	Summer bank holiday
2016-11-30	SCT	St Andrew’s Day
2016-12-26	EAW	Boxing Day
2016-12-26	NIR	Boxing Day
2016-12-26	SCT	Boxing Day
2016-12-27	EAW	Christmas Day
2016-12-27	NIR	Christmas Day
2016-12-27	SCT	Christmas Day
2017-01-02	EAW	New Year’s Day
2017-01-02	NIR	New Year’s Day
2017-01-02	SCT	2nd January
2017-01-03	SCT	New Year’s Day
2017-03-17	NIR	St Patrick’s Day
2017-04-14	EAW	Good Friday
2017-04-14	NIR	Good Friday
2017-04-14	SCT	Good Friday
2017-04-17	EAW	Easter Monday
2017-04-17	NIR	Easter Monday
2017-05-01	EAW	Early May bank holiday
2017-05-01	NIR	Early May bank holiday
2017-05-01	SCT	Early May bank holiday
2017-05-29	EAW	Spring bank holiday
2017-05-29	NIR	Spring bank holiday
2017-05-29	SCT	Spring bank holiday
2017-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2017-08-07	SCT	Summer bank holiday
2017-08-28	EAW	Summer bank holiday
2017-08-28	NIR	Summer bank holiday
2017-11-30	SCT	St Andrew’s Day
2017-12-25	EAW	Christmas Day
2017-12-25	NIR	Christmas Day
2017-12-25	SCT	Christmas Day
2017-12-26	EAW	Boxing Day
2017-12-26	NIR	Boxing Day
2017-12-26	SCT	Boxing Day
2018-01-01	EAW	New Year’s Day
2018-01-01	NIR	New Year’s Day
2018-01-01	SCT	New Year’s Day
2018-01-02	SCT	2nd January
2018-03-19	NIR	St Patrick’s Day
2018-03-30	EAW	Good Friday
2018-03-30	NIR	Good Friday
2018-03-30	SCT	Good Friday
2018-04-02	EAW	Easter Monday
2018-04-02	NIR	Easter Monday
2018-05-07	EAW	Early May bank holiday
2018-05-07	NIR	Early May bank holiday
2018-05-07	SCT	Early May bank holiday
2018-05-28	EAW	Spring bank holiday
2018-05-28	NIR	Spring bank holiday
2018-05-28	SCT	Spring bank holiday
2018-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2018-08-06	SCT	Summer bank holiday
2018-08-27	EAW	Summer bank holiday
2018-08-27	NIR	Summer bank holiday
2018-11-30	SCT	St Andrew’s Day
2018-12-25	EAW	Christmas Day
2018-12-25	NIR	Christmas Day
2018-12-25	SCT	Christmas Day
2018-12-26	EAW	Boxing Day
2018-12-26	NIR	Boxing Day
2018-12-26	SCT	Boxing Day
2019-01-01	EAW	New Year’s Day
2019-01-01	NIR	New Year’s Day
2019-01-01	SCT	New Year’s Day
2019-01-02	SCT	2nd January
2019-03-18	NIR	St Patrick’s Day
2019-04-19	EAW	Good Friday
2019-04-19	NIR	Good Friday
2019-04-19	SCT	Good Friday
2019-04-22	EAW	Easter Monday
2019-04-22	NIR	Easter Monday
2019-05-06	EAW	Early May bank holiday
2019-05-06	NIR	Early May bank holiday
2019-05-06	SCT	Early May bank holiday
2019-05-27	EAW	Spring bank holiday
2019-05-27	NIR	Spring bank holiday
2019-05-27	SCT	Spring bank holiday
2019-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2019-08-05	SCT	Summer bank holiday
2019-08-26	EAW	Summer bank holiday
2019-08-26	NIR	Summer bank holiday
2019-12-02	SCT	St Andrew’s Day
2019-12-25	EAW	Christmas Day
2019-12-25	NIR	Christmas Day
2019-12-25	SCT	Christmas Day
2019-12-26	EAW	Boxing Day
2019-12-26	NIR	Boxing Day
2019-12-26	SCT	Boxing Day
2020-01-01	EAW	New Year’s Day
2020-01-01	NIR	New Year’s Day
2020-01-01	SCT	New Year’s Day
2020-01-02	SCT	2nd January
2020-03-17	NIR	St Patrick’s Day
2020-04-10	EAW	Good Friday
2020-04-10	NIR	Good Friday
2020-04-10	SCT	Good Friday
2020-04-13	EAW	Easter Monday
2020-04-13	NIR	Easter Monday
2020-05-08	EAW	Early May bank holiday (VE day)
2020-05-08	NIR	Early May bank holiday (VE day)
2020-05-08	SCT	Early May bank holiday (VE day)
2020-05-25	EAW	Spring bank holiday
2020-05-25	NIR	Spring bank holiday
2020-05-25	SCT	Spring bank holiday
2020-07-13	NIR	Battle of the Boyne (Orangemen’s Day)
2020-08-03	SCT	Summer bank holiday
2020-08-31	EAW	Summer bank holiday
2020-08-31	NIR	Summer bank holiday
2020-11-30	SCT	St Andrew’s Day
2020-12-25	EAW	Christmas Day
2020-12-25	NIR	Christmas Day
2020-12-25	SCT	Christmas Day
2020-12-28	EAW	Boxing Day
2020-12-28	NIR	Boxing Day
2020-12-28	SCT	Boxing Day
2021-01-01	EAW	New Year’s Day
2021-01-01	NIR	New Year’s Day
2021-01-01	SCT	New Year’s Day
2021-01-04	SCT	2nd January
2021-03-17	NIR	St Patrick’s Day
2021-04-02	EAW	Good Friday
2021-04-02	NIR	Good Friday
2021-04-02	SCT	Good Friday
2021-04-05	EAW	Easter Monday
2021-04-05	NIR	Easter Monday
2021-05-03	EAW	Early May bank holiday
2021-05-03	NIR	Early May bank holiday
2021-05-03	SCT	Early May bank holiday
2021-05-31	EAW	Spring bank holiday
2021-05-31	NIR	Spring bank holiday
2021-05-31	SCT	Spring bank holiday
2021-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2021-08-02	SCT	Summer bank holiday
2021-08-30	EAW	Summer bank holiday
2021-08-30	NIR	Summer bank holiday
2021-11-30	SCT	St Andrew’s Day
2021-12-27	EAW	Christmas Day
2021-12-27	NIR	Christmas Day
2021-12-27	SCT	Christmas Day
2021-12-28	EAW	Boxing Day
2021-12-28	NIR	Boxing Day
2021-12-28	SCT	Boxing Day
