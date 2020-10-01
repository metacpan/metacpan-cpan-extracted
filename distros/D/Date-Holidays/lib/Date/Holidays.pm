package Date::Holidays;

use strict;
use warnings;
use vars qw($VERSION);
use Locale::Country qw(all_country_codes code2country);
use Module::Load qw(load);
use DateTime;
use TryCatch;
use Scalar::Util qw(blessed);

use base 'Date::Holidays::Adapter';

$VERSION = '1.25';

sub new {
    my ( $class, %params ) = @_;

    my $self = bless {
        _inner_object => undef,
        _inner_class  => undef,
        _countrycode  => undef,
        },
        ref $class || $class;

    if ( $params{'countrycode'} ) {
        if ( code2country( $params{countrycode} ) ) {
            $self->{'_countrycode'} = uc $params{countrycode};
        }
        else {
            $self->{'_countrycode'} = $params{countrycode};
        }

        try {
            $self->{'_inner_class'} = $self->_fetch(
                {   nocheck     => $params{'nocheck'},
                    countrycode => $params{'countrycode'},
                }
            );
        }

    }
    else {
        die "No country code specified\n";
    }

    if (   $self
        && $self->{'_inner_class'}
        && $self->{'_inner_class'}->can('new') )
    {
        try {
            my $adapter = $self->{'_inner_class'}->new(
                countrycode => $self->{'_countrycode'},
                nocheck     => $params{'nocheck'},
            );

            if ($adapter) {
                $self->{'_inner_object'} = $adapter;
            }
            else {
                warn "Adapter not defined\n";
                $self = undef;
            }
        }
        catch ($error) {
            warn "Unable to initialize adapter: $error\n";
            $self = undef;
        }

    }
    elsif ( !$self->{'_inner_class'} ) {
        warn "No inner class instantiated\n";
        $self = undef;
    }

    return $self;
}

sub holidays {
    my ( $self, %params ) = @_;

    # Our result
    my $r;

    # Did we get a country list
    if ( not $params{'countries'} ) {

        #No countries - so we create a list
        my @countries = all_country_codes();    # From Locale::Country
        @countries = sort @countries;

        # We stick the complete list of countries to the parameters
        $params{'countries'} = \@countries;
    }

    $r = $self->{'_inner_object'}->holidays(%params);

    return $r;
}

sub is_holiday {
    my ( $self, %params ) = @_;

    # Our result
    my $r;

    if ( not $params{'countries'} ) {
        if ( blessed $self) {
            $r = $self->{'_inner_object'}->is_holiday(%params);
        }
        else {
            my @countries = all_country_codes();    # From Locale::Country
            @countries = sort @countries;
            $params{'countries'} = \@countries;

            $r = __PACKAGE__->_check_countries(%params);
        }

    }
    else {
        if ( blessed $self) {
            $r = $self->_check_countries(%params);

        }
        else {
            $r = __PACKAGE__->_check_countries(%params);
        }
    }

    return $r;
}

sub holidays_dt {
    my ( $self, %params ) = @_;

    my $hashref = $self->holidays( year => $params{'year'} );
    my %dts;

    foreach my $h ( keys %{$hashref} ) {
        my ( $month, $day ) = $h =~ m{
            \A      # Beginning of string
            (\d{2}) # 2 digits indicating the month
            (\d{2}) # 2 digits indicating the day
            \Z      # End of string
        }xsm;
        my $dt = DateTime->new(
            year  => $params{'year'},
            month => $month,
            day   => $day,
        );
        $dts{ $hashref->{$h} } = $dt;
    }

    return \%dts;
}

sub _check_countries {
    my ( $self, %params ) = @_;

    my $result             = {};
    my $precedent_calendar = q{};

    foreach my $country ( @{ $params{'countries'} } ) {

        #The list of countries is ordered
        if ( $country =~ m/\A[+](\w+)/xism ) {
            $country            = $1;
            $precedent_calendar = $country;
        }

        try {
            my $dh = $self->new(
                countrycode => $country,
                nocheck     => $params{nocheck}
            );

            if ( !$dh ) {
                my $countryname = code2country($country);
                my $countrycode = $country;

                die
                    "Unable to initialize Date::Holidays for country: $countrycode - $countryname\n";
            }

            my %prepared_parameters = (
                year  => $params{'year'},
                month => $params{'month'},
                day   => $params{'day'},
            );

            # did we receive special regions parameter?
            if ( $params{regions} ) {
                $prepared_parameters{regions} = $params{regions};
            }

            # did we receive special state parameter?
            if ( $params{state} ) {
                $prepared_parameters{state} = $params{state};
            }

            my $r = $dh->is_holiday(%prepared_parameters);

            if ( $precedent_calendar eq $country ) {
                $self->{precedent_calendar} = $dh;
            }

            # handling precedent calendar
            if (    $precedent_calendar
                and $precedent_calendar ne $country )
            {

                my $holiday = $self->{precedent_calendar}
                    ->is_holiday(%prepared_parameters);

                # our precedent calendar dictates overwrite or nullification
                if ( defined $holiday ) {
                    $r = $holiday;
                }
            }

            if ( defined $r ) {
                $result->{$country} = $r;
            }
        }
        catch ($error) {
            warn "$error\n";
        }
    }

    return $result;
}

sub is_holiday_dt {
    my ( $self, $dt ) = @_;

    return $self->is_holiday(
        year  => $dt->year,
        month => $dt->month,
        day   => $dt->day,
    );
}

sub _fetch {
    my ( $self, $params ) = @_;

    # Do we have a country code?
    if ( not $self->{'_countrycode'} and not $params->{countrycode} ) {
        die "No country code specified\n";
    }

    my $countrycode = $params->{countrycode} || $self->{'_countrycode'};

    # Do we do country code assertion?
    if ( !$params->{'nocheck'} ) {

        # Is our country code valid or local?
        if ( $countrycode !~ m/\Alocal\Z/xism
            and not code2country($countrycode) )
        {    #from Locale::Country
            die "$countrycode is not a valid country code\n";
        }
    }

    # Trying to load adapter module for country code
    my $module;

    try {
        # We load an adapter implementation
        if ( $countrycode =~ m/\Alocal\Z/xism ) {
            $module = 'Date::Holidays::Adapter::Local';
        }
        elsif ( code2country($countrycode) ) {
            $module = 'Date::Holidays::Adapter::' . uc $countrycode;
        }
        else {
            $module = 'Date::Holidays::Adapter::' . $countrycode;
        }

        $module = $self->_load($module);

    }
    catch ($error) {
        warn "Unable to load module: $module - $error\n";

        try {

            # We load an adapter implementation
            $module = 'Date::Holidays::Adapter::' . $countrycode;

            if ( $module = $self->_load($module) ) {
                warn "we got a module and we return\n";
            }

        }
        catch ($error) {
            warn "Unable to load module: $module - $error\n";

            $module = 'Date::Holidays::Adapter';
            $module = $self->_load($module);
        };
    };

    # Returning name of loaded module upon success
    return $module;
}

1;

__END__

=pod

=begin markdown

# Date::Holidays

[![CPAN version](https://badge.fury.io/pl/Date-Holidays.svg)](http://badge.fury.io/pl/Date-Holidays)
![stability-stable](https://img.shields.io/badge/stability-stable-green.svg)
[![Build Status](https://travis-ci.org/jonasbn/perl-date-holidays.svg?branch=master)](https://travis-ci.org/jonasbn/perl-date-holidays)
[![Coverage Status](https://coveralls.io/repos/github/jonasbn/perl-date-holidays/badge.svg?branch=master)](https://coveralls.io/github/jonasbn/perl-date-holidays?branch=master)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

<!-- MarkdownTOC autoanchor=false -->

<!-- /MarkdownTOC -->

=end markdown

=head1 NAME

Date::Holidays - Date::Holidays::* adapter and aggregator for all your holiday needs

=head1 VERSION

The documentation describes version 1.25 of Date::Holidays

=head1 FEATURES

=over

=item * Exposes a uniform interface towards modules in the Date::Holidays::* namespace

=item * Inquire whether a certain date is a holiday in a specific country or a set of countries

=item * Inquire for a holidays for a given year for a specific country or a set of countries

=item * Overwrite/rename/suppress national holidays with your own calendar

=back

=head1 SYNOPSIS

    use Date::Holidays;

    # Initialize a national holidays using the ISO 3361 country code
    my $dh = Date::Holidays->new(
        countrycode => 'dk'
    );

    # Inquire and get a local name for a holiday if it is a national holiday
    my $holidayname = $dh->is_holiday(
        year  => 2004,
        month => 12,
        day   => 25
    );

    # Inquire and get a set of local names for national holiday in a given country
    my $hashref = $dh->holidays(
        year => 2004
    );

    # Inquire and get local names for a set of countries, where the specific date is a
    # national holiday
    $holidays_hashref = Date::Holidays->is_holiday(
        year      => 2004,
        month     => 12,
        day       => 25,
        countries => ['se', 'dk', 'no'],
    );

    foreach my $country (keys %{$holidays_hashref}) {
        print $holidays_hashref->{$country}."\n";
    }

    # Example of a module with additional parameters
    # Australia is divided into states with local holidays
    # using ISO-3166-2 codes
    my $dh = Date::Holidays->new(
        countrycode => 'au'
    );

    $holidayname = $dh->is_holiday(
        year  => 2004,
        month => 12,
        day   => 25,
        state => 'TAS',
    );

    $hashref = $dh->holidays(
        year => 2004
        state => 'TAS',
    );

    # Another example of a module with additional parameters
    # Great Britain is divided into regions with local holidays
    # using ISO-3166-2 codes
    my $dh = Date::Holidays->new(
        countrycode => 'gb'
    );

    $holidayname = $dh->is_holiday(
        year    => 2014,
        month   => 12,
        day     => 25,
        regions => ['EAW'],
    );

    $hashref = $dh->holidays(
        year    => 2014
        regions => ['EAW'],
    );

=head1 DESCRIPTION

Date::Holidays is an adapters exposing a uniform API to a set of dsitributions
in the Date::Holidays::* namespace. All of these modules deliver methods and
information on national calendars, but no standardized API exist.

The distributions more or less follow a I<de> I<facto> standard (see: also the generic
adapter L<Date::Holidays::Adapter|https://metacpan.org/pod/Date::Holidays::Adapter>), but the adapters are implemented to uniform
this and Date::Holidays exposes a more readable API and at the same time it
provides an OO interface, to these diverse implementations, which primarily
holds a are produceral.

As described below it is recommended that a certain API is implemented (SEE:
B<holidays> and B<is_holiday> below), but taking the adapter strategy into
consideration this does not matter, or we attempt to do what we can with what is
available on CPAN.

If you are an module author/CPAN contributor who wants to comply to the suggested,
either look at some of the other modules in the Date::Holidays::* namespace to get an
idea of the I<de> I<facto> standard or have a look at L<Date::Holidays::Abstract|https://metacpan.org/pod/Date::Holidays::Abstract> and
L<Date::Holidays::Super|https://metacpan.org/pod/Date::Holidays::Super> - or write me.

In addition to the adapter feature, Date::Holidays also do aggregation, so you
can combine calendars and you can overwrite and redefined existing calendars.

=head2 DEFINING YOUR OWN CALENDAR

As mentioned in the FEATURES section it is possible to create your own local calendar.

This can be done using a L<JSON|https://metacpan.org/pod/JSON> file with your local definitions:

    {
        "1501" : "jonasbn's birthday"
    }

This also mean you can overwrite your national calendar:

    {
        "1225" : ""
    }


You can specify either month plus day for a recurring holiday. If you you want to define
a holiday for a specific year, simply extend the date with year:

    {
        "201.1625" : ""
    }

In order for the calendar to be picked up by Date::Holidays, set the environment variable:

    $HOLIDAYS_FILE

This should point to the JSON file.

=head1 SUBROUTINES/METHODS

=head2 new

This is the constructor. It takes the following parameters:

=over

=item countrycode (MANDATORY, see below), unique two letter code representing a country name.  Please refer to ISO3166 (or L<Locale::Country|https://metacpan.org/pod/Locale::Country>)

=item nocheck (optional), if set to true the countrycode specified will not be validated against a list of known country codes for existance, so you can build fake holidays for fake countries, I currently use this for test. This parameter might disappear in the future.

=back

The constructor loads the module from Date::Holidays::*, which matches the
country code and returns a Date::Holidays module with the specified module
loaded and ready to answer to any of the following methods described below, if
these are implemented - of course.

If no countrycode is provided or the class is not able to load a module, nothing
is returned.

    my $dh = Date::Holidays->new(countrycode => 'dk')
        or die "No holidays this year, get back to work!\n";

=head2 holidays

This is a wrapper around the loaded module's B<holidays> method if this is
implemented. If this method is not implemented it tries <countrycode>_holidays.

Takes 3 optional named arguments:

=over

=item * year, four digit parameter representing year

=item * state, ISO-3166-2 code for a state

Not all countries support this parameter

=item * regions, pointing to a reference to an array of ISO-3166-2 code for regions

Not all countries support this parameter

=back

    $hashref = $dh->holidays(year => 2007);

=head2 holidays_dt

This method is similar to holidays. It takes one named argument b<year>.

The result is a hashref just as for B<holidays>, but instead the names
of the holidays are used as keys and the values are DateTime objects.

=head2 is_holiday

This is yet another wrapper around the loaded module's B<is_holiday>
method if this is implemented. Also if this method is not implemented
it tries is_<countrycode>_holiday.

Takes 6 optional named arguments:

=over

=item * year, four digit parameter representing year

=item * month, 1-12, representing month

=item * day, 1-31, representing day

=item * countries (OPTIONAL), a list of ISO3166 country codes

=item * state, ISO-3166-2 code for a state. Not all countries support this parameter

=item * regions, pointing to a reference to an array of ISO-3166-2 code for regions. Not all countries support this parameter

=back

is_holiday returns the name of a holiday is present in the country specified by
the country code provided to the Date::Holidays constructor.

    $name = $dh->is_holiday(year => 2007, day => 24, month => 12);

If this method is called using the class name B<Date::Holidays>, all known
countries are tested for a holiday on the specified date, unless the countries
parameter specifies a subset of countries to test.

    $hashref = Date::Holidays->is_holiday(year => 2007, day => 24, month => 12);

In the case where a set of countries are tested the return value from the method
is a hashref with the country codes as keys and the values as the result.

=over

=item C<undef> if the country has no module or the data could not be obtained

=item a name of the holiday if a holiday is present

=item an empty string if the a module was located but the day is not a holiday

=back

=head2 is_holiday_dt

This method is similar to is_holiday, but instead of 3 separate arguments it
only takes a single argument, a DateTime object.

Return 1 for true if the object is a holiday and 0 for false if not.

=head1 DEVELOPING A DATE::HOLIDAYS::* MODULE

There is no control of the Date::Holidays::* namespace at all, so I am by no
means an authority, but this is recommendations on order to make the modules
in the Date::Holidays more uniform and thereby more usable.

If you want to participate in the effort to make the Date::Holidays::* namespace
even more usable, feel free to do so, your feedback and suggestions will be
more than welcome.

If you want to add your country to the Date::Holidays::* namespace, please feel
free to do so. If a module for you country is already present, I am sure the
author would not mind patches, suggestions or even help.

If however you country does not seem to be represented in the namespace, you
are more than welcome to become the author of the module in question.

Please note that the country code is expected to be a two letter code based on
ISO3166 (or L<Locale::Country|https://metacpan.org/pod/Locale::Country>).

As an experiment I have added two modules to the namespace,
L<Date::Holidays::Abstract|https://metacpan.org/pod/Date::Holidays::Abstract> and L<Date::Holidays::Super|https://metacpan.org/pod/Date::Holidays::Super>, abstract is attempt
to make sure that the module implements some, by me, expected methods.

So by using abstract your module will not work until it follows the the abstract
layed out for a Date::Holidays::* module. Unfortunately the module will only
check for the presence of the methods not their prototypes.

L<Date::Holidays::Super|https://metacpan.org/pod/Date::Holidays::Super> is for the lazy programmer, it implements the necessary
methods as stubs and there for do not have to implement anything, but your
module will not return anything of value. So the methods need to be overwritten
in order to comply with the expected output of a Date::Holidays::* method.

The methods which are currently interesting in a Date::Holidays::* module are:

=over

=item is_holiday

Takes 3 arguments: year, month, day and returns the name of the holiday as a
scalar in the national language of the module context in question. Returns
undef if the requested day is not a holiday.

    Modified example taken from: L<Date::Holidays::DK|https://metacpan.org/pod/Date::Holidays::DK>

    use Date::Holidays::DK;
    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];

    $year  += 1900;
    $month += 1;
    print "Woohoo" if is_holiday( $year, $month, $day );

    #The actual method might not be implemented at this time in the
    #example module.

=item is_<countrycode>_holiday

Same as above.

This method however should be a wrapper of the above method (or the other way
around).

=item holidays

Takes 1 argument: year and returns a hashref containing all of the holidays in
specied for the country, in the national language of the module context in
question.

The keys are the dates, month + day in two digits each concatenated.

    Modified example taken from: L<Date::Holidays::PT|https://metacpan.org/pod/Date::Holidays::PT>

    my $h = holidays($year);
    printf "Jan. 1st is named '%s'\n", $h->{'0101'};

    #The actual method might not be implemented at this time in the
    #example module.

=item <countrycode>_holidays

This method however should be a wrapper of the above method (or the other way
around).

=back

B<Only> B<is_holiday> and B<holidays> are implemented in
L<Date::Holidays::Super|https://metacpan.org/pod/Date::Holidays::Super> and are required by L<Date::Holidays::Abstract|https://metacpan.org/pod/Date::Holidays::Abstract>.

=head2 ADDITIONAL PARAMETERS

Some countries are divided into regions or similar and might require additional
parameters in order to give more exact holiday data.

This is handled by adding additional parameters to B<is_holiday> and
B<holidays>.

These parameters are left to the module authors descretion and the actual
Date::Holidays::* module should be consulted.

    Example Date::Holidays::AU

    use Date::Holidays::AU qw( is_holiday );

    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    my ($state) = 'VIC';
    print "Excellent\n" if is_holiday( $year, $month, $day, $state );

=head1 DEVELOPING A DATE::HOLIDAYS::ADAPTER CLASS

If you want to contribute with an adapter, please refer to the documentation in
L<Date::Holidays::Adapter|https://metacpan.org/pod/Date::Holidays::Adapter>.

=head1 DEVELOPING ON DATE::HOLIDAYS

Date::Holidays is distributed and maintained using L<Dist::Zilla|https://metacpan.org/pod/Dist::Zilla>

=head2 RUNNING THE TEST SUITE

The test suite can be executed using

    $ dzil test

The test suite, which attempts lots scenarios does emit a lot of warnings, so it is recommended to suppress C<STDERR> by redirecting it to C</dev/null>

    $ dzil test 2> /dev/null

To enable author tests aimed at asserting distribution and code quality in addition to functionality, use the C<--author> flag

    $ dzil test --author 2> /dev/null

If you are working on a release, use the C<--release> flag

    $ dzil test --release 2> /dev/null

The release flag is implicit for the L<Dist::Zilla|https://metacpan.org/pod/Dist::Zilla> release command.

=head1 DIAGNOSTICS

=over

=item * No country code specified

No country code has been specified.

=item * Unable to initialize Date::Holidays for country: <countrycode>

This message is emitted if a given country code cannot be loaded.

=back

=head1 CONFIGURATION AND ENVIRONMENT

As mentioned in the section on defining your own calendar. You have to
set the environment variable:

    $HOLIDAYS_FILE

This environment variable should point to a JSON file containing holiday definitions
to be used by L<Date::Holidays::Adapter::Local|https://metacpan.org/pod/Date::Holidays::Local>.

=head1 DEPENDENCIES

=over

=item * L<Carp|https://metacpan.org/pod/Carp>

=item * L<DateTime|https://metacpan.org/pod/DateTime>

=item * L<Locale::Country|https://metacpan.org/pod/Locale::Country>

=item * L<Module::Load|https://metacpan.org/pod/Module::Load>

=item * L<TryCatch|https://metacpan.org/pod/TryCatch>

=item * L<Scalar::Util|https://metacpan.org/pod/Scalar::Util>

=item * L<JSON|https://metacpan.org/pod/JSON>

=item * L<File::Slurp|https://metacpan.org/pod/File::Slurp>

=back

=head2 FOR TESTING

=over

=item * L<Test::Class|https://metacpan.org/pod/Test::Class>

=item * L<Test::More|https://metacpan.org/pod/Test::More>

=item * L<FindBin|https://metacpan.org/pod/FindBin>

=back

Please see the F<cpanfile> included in the distribution for a complete listing.

=head1 INCOMPATIBILITIES

Currently the following CPAN Date::Holidays distributions are unsupported:

=over

=item * L<Date::Holidays::UK|https://metacpan.org/pod/Date::Holidays::UK> only supports bank holidays until 2007

=item * L<Date::Holidays::UK::EnglandAndWales|https://metacpan.org/pod/Date::Holidays::UK::EnglandAndWales> only supports bank holidays until 2014

=back

Additional issues might be described the specific adapter classes or their respective adaptees.

=head1 BUGS AND LIMITATIONS

Currently we have an exception for the L<Date::Holidays::AU|https://metacpan.org/pod/Date::Holidays::AU> module, so the
additional parameter of state is defaulting to 'VIC', please refer to the POD
for L<Date::Holidays::AU|https://metacpan.org/pod/Date::Holidays::AU> for documentation on this.

L<Date::Holidays::DE|https://metacpan.org/pod/Date::Holidays::DE> and L<Date::Holidays::UK|https://metacpan.org/pod/Date::Holidays::UK> does not implement the
B<holidays> methods

The adaptee module for L<Date::Holidays::Adapter::JP|https://metacpan.org/pod/Date::Holidays::Adapter::JP> is named:
L<Date::Japanese::Holiday|https://metacpan.org/pod/Date::Japanese::Holiday>, but the adapter class is following the general
adapter naming of Date::Holidays::Adapter::<countrycode>.

The adapter for L<Date::Holidays::PT|https://metacpan.org/pod/Date::Holidays::PT>, L<Date::Holidays::Adapter::PT|https://metacpan.org/pod/Date::Holidays::Adapter::PT> does not
implement the B<is_pt_holiday> method. The pattern used is an object adapter
pattern and inheritance is therefor not used, it is my hope that I can
make this work with some Perl magic.

=head1 ISSUE REPORTING

Please report any bugs or feature requests using B<GitHub>.

=over

=item * L<GitHub Issues|https://github.com/jonasbn/perl-date-holidays/issues>

=back

=head1 TEST COVERAGE

Coverage reports are available via L<Coveralls.io|https://coveralls.io/github/jonasbn/perl-date-holidays?branch=master>

=begin markdown

[![Coverage Status](https://coveralls.io/repos/github/jonasbn/perl-date-holidays/badge.svg?branch=master)](https://coveralls.io/github/jonasbn/perl-date-holidays?branch=master)

=end markdown

Without the actual holiday implementations installed/available coverage will be very low.

Please see L<Task::Date::Holidays|https://metacpan.org/pod/Task::Date::Holidays>, which is a distribution, which can help in installing all the wrapped (adapted and aggregated) distributions.

=head1 SEE ALSO

=over

=item * L<Date::Holidays::AT|https://metacpan.org/pod/Date::Holidays::AT>

=item * L<Date::Holidays::Adapter::AT|https://metacpan.org/pod/Date::Holidays::Adapter::AT>

=item * L<Date::Holidays::AU|https://metacpan.org/pod/Date::Holidays::AU>

=item * L<Date::Holidays::Adapter::AU|https://metacpan.org/pod/Date::Holidays::Adapter::AU>

=item * L<Date::Holidays::BR|https://metacpan.org/pod/Date::Holidays::BR>

=item * L<Date::Holidays::Adapter::BR|https://metacpan.org/pod/Date::Holidays::Adapter::BR>

=item * L<Date::Holidays::AW|https://metacpan.org/pod/Date::Holidays::AW>

=item * L<Date::Holidays::Adapter::AW|https://metacpan.org/pod/Date::Holidays::Adapter::AW>

=item * L<Date::Holidays::BY|https://metacpan.org/pod/Date::Holidays::BY>

=item * L<Date::Holidays::Adapter::BY|https://metacpan.org/pod/Date::Holidays::Adapter::BY>

=item * L<Date::Holidays::CA|https://metacpan.org/pod/Date::Holidays::CA>

=item * L<Date::Holidays::CA_ES|https://metacpan.org/pod/Date::Holidays::CA_ES>

=item * L<Date::Holidays::Adapter::CA_ES|https://metacpan.org/pod/Date::Holidays::Adapter::CA_ES>

=item * L<Date::Holidays::CN|https://metacpan.org/pod/Date::Holidays::CN>

=item * L<Date::Holidays::Adapter::CN|https://metacpan.org/pod/Date::Holidays::Adapter::CN>

=item * L<Date::Holidays::CZ|https://metacpan.org/pod/Date::Holidays::CZ>

=item * L<Date::Holidays::Adapter::CZ|https://metacpan.org/pod/Date::Holidays::Adapter::CZ>

=item * L<Date::Holidays::DE|https://metacpan.org/pod/Date::Holidays::DE>

=item * L<Date::Holidays::Adapter::DE|https://metacpan.org/pod/Date::Holidays::Adapter::DE>

=item * L<Date::Holidays::DK|https://metacpan.org/pod/Date::Holidays::DK>

=item * L<Date::Holidays::Adapter::DK|https://metacpan.org/pod/Date::Holidays::Adapter::DK>

=item * L<Date::Holidays::ES|https://metacpan.org/pod/Date::Holidays::ES>

=item * L<Date::Holidays::Adapter::ES|https://metacpan.org/pod/Date::Holidays::Adapter::ES>

=item * L<Date::Holidays::FR|https://metacpan.org/pod/Date::Holidays::FR>

=item * L<Date::Holidays::Adapter::FR|https://metacpan.org/pod/Date::Holidays::Adapter::FR>

=item * L<Date::Holidays::GB|https://metacpan.org/pod/Date::Holidays::GB>

=item * L<Date::Holidays::Adapter::GB|https://metacpan.org/pod/Date::Holidays::Adapter::GB>

=item * L<Date::Holidays::KR|https://metacpan.org/pod/Date::Holidays::KR>

=item * L<Date::Holidays::Adapter::KR|https://metacpan.org/pod/Date::Holidays::Adapter::KR>

=item * L<Date::Holidays::KZ|https://metacpan.org/pod/Date::Holidays::KZ>

=item * L<Date::Holidays::Adapter::KZ|https://metacpan.org/pod/Date::Holidays::Adapter::KZ>

=item * L<Date::Holidays::NL|https://metacpan.org/pod/Date::Holidays::NL>

=item * L<Date::Holidays::Adapter::NL|https://metacpan.org/pod/Date::Holidays::Adapter::NL>

=item * L<Date::Holidays::NO|https://metacpan.org/pod/Date::Holidays::NO>

=item * L<Date::Holidays::Adapter::NO|https://metacpan.org/pod/Date::Holidays::Adapter::NO>

=item * L<Date::Holidays::NZ|https://metacpan.org/pod/Date::Holidays::NZ>

=item * L<Date::Holidays::Adapter::NZ|https://metacpan.org/pod/Date::Holidays::Adapter::NZ>

=item * L<Date::Holidays::PL|https://metacpan.org/pod/Date::Holidays::PL>

=item * L<Date::Holidays::Adapter::PL|https://metacpan.org/pod/Date::Holidays::Adapter::PL>

=item * L<Date::Holidays::PT|https://metacpan.org/pod/Date::Holidays::PT>

=item * L<Date::Holidays::Adapter::PT|https://metacpan.org/pod/Date::Holidays::Adapter::PT>

=item * L<Date::Holidays::RU|https://metacpan.org/pod/Date::Holidays::RU>

=item * L<Date::Holidays::Adapter::RU|https://metacpan.org/pod/Date::Holidays::Adapter::RU>

=item * L<Date::Holidays::SK|https://metacpan.org/pod/Date::Holidays::SK>

=item * L<Date::Holidays::Adapter::SK|https://metacpan.org/pod/Date::Holidays::Adapter::SK>

=item * L<Date::Holidays::UK|https://metacpan.org/pod/Date::Holidays::UK>

=item * L<Date::Holidays::Adapter::UK|https://metacpan.org/pod/Date::Holidays::Adapter::UK>

=item * L<Date::Holidays::USFederal|https://metacpan.org/pod/Date::Holidays::USFederal>

=item * L<Date::Holidays::Adapter::USFederal|https://metacpan.org/pod/Date::Holidays::Adapter::USFederal>

=item * L<Date::Japanese::Holiday|https://metacpan.org/pod/Date::Japanese::Holiday>

=item * L<Date::Holidays::Adapter::JP|https://metacpan.org/pod/Date::Holidays::Adapter::JP>

=item * L<Date::Holidays::UA|https://metacpan.org/pod/Date::Holidays::UA>

=item * L<Date::Holidays::Adapter::UA|https://metacpan.org/pod/Date::Holidays::Adapter::UA>

=item * L<Date::Holidays::Adapter|https://metacpan.org/pod/Date::Holidays::Adapter>

=item * L<Date::Holidays::Abstract|https://metacpan.org/pod/Date::Holidays::Abstract>

=item * L<Date::Holidays::Super|https://metacpan.org/pod/Date::Holidays::Super>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Wesley Schwengle (WATERKIP) author of Date::Holidays::NL and Date::Holidays::AW for reaching out and letting me know of their existance

=item * Karen Etheridge (ETHER)

=item * Neil Bowers (NEILB)

=item * Miquel Ruiz, PR fixing a bug with regions for ES, supporting Data::Holidays::CA_ES resulting in 1.22

=item * Denis Boyun, PR introducing Date::Holidays::UA resulting in 1.19

=item * Mario Minati, for telling me about the states in Date::Holidays::DE resulting in 1.17

=item * Vladimir Varlamov, PR introducing Date::Holidays::KZ resulting in 1.07

=item * CHORNY (Alexandr Ciornii), Github issue #10, letting me know I included local/ by accident, resulting in release 1.05

=item * Vladimir Varlamov, PR introducing Date::Holidays::BY resulting in 1.04

=item * Joseph M. Orost, bug report resulting in 1.03

=item * Alexander Nalobin, patch for using of Date::Holidays::RU, 1.01

=item * Gabor Szabo, patch assisting META data generation

=item * Florian Merges for feedback and pointing out a bug in Date::Holidays, author of Date::Holidays::ES

=item * COG (Jose Castro), Date::Holidays::PT author

=item * RJBS (Ricardo Signes), POD formatting

=item * MRAMBERG (Marcus Ramberg), Date::Holidays::NO author

=item * BORUP (Christian Borup), DateTime suggestions

=item * LTHEGLER (Lars Thegler), Date::Holidays::DK author

=item * shild on L<use.perl.org|http://use.perl.org/comments.pl?sid=28993&cid=43889>, CPAN tester

=item * CPAN testers in general, their work is invaluable

=item * All of the authors/contributors of Date::Holidays::* modules

=back

=head1 AUTHOR

Jonas B., (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Date-Holidays and related modules are (C) by Jonas B., (jonasbn)
2004-2020

Date-Holidays and related modules are released under the Artistic License 2.0

Image used on L<website|https://jonasbn.github.io/perl-date-holidays/> is under copyright by L<Tim Mossholder|https://unsplash.com/photos/C8jNJslQM3A>

=cut
