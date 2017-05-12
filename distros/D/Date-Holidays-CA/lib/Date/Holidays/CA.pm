# Date::Holidays::CA
#
# This module is free software!  You can copy, modify, share and
# distribute it under the same license as Perl itself.
# 
# Rick Scott 
# rick@shadowspar.dyndns.org
#
# Sun Oct 25 14:32:20 EDT 2009

=encoding utf8

=head1 NAME 

Date::Holidays::CA - Holidays for Canadian locales

=head1 SYNOPSIS

    # procedural approach 
  
    use Date::Holidays::CA qw(:all);
  
    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;
    
    print 'Woot!' if is_holiday($year, $month, $day, {province => 'BC'});
  
    my $calendar = holidays($year, {province => 'BC'}); 
    print $calendar->('0701');              # "Canada Day/Fête du Canada"
    
  
    # object-oriented approach
  
    use DateTime;
    use Date::Holidays::CA;
  
    my $dhc = Date::Holidays::CA->new({ province => 'QC' });
  
    print 'Woot!' if $dhc->is_holiday(DateTime->today); 
  
    my $calendar = $dhc->holidays_dt(DateTime->today->year); 
    print join keys %$calendar, "\n";       # lists holiday names for QC



=head1 DESCRIPTION

Date::Holidays::CA determines public holidays for Canadian jurisdictions.
Its interface is a superset of that provided by Date::Holidays -- read
on for details.

=cut 


package Date::Holidays::CA;

use 5.006;
use strict;
use warnings;
use Carp;
use DateTime;
use DateTime::Event::Easter;


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    is_holiday
    is_ca_holiday
    is_holiday_dt
    holidays
    ca_holidays
    holidays_dt
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.03';


=head1 FUNCTIONS / METHODS

=head2 Class Methods 

=head3 new()

Create a new Date::Holidays::CA object.  Parameters should be given as
a hashref of key-value pairs.

    my $dhc = Date::Holidays::CA->new();        # defaults

    my $dhc = Date::Holidays::CA->new({
        province => 'ON', language => 'EN' 
    });

Two parameters can be specified: B<province> and B<language>.

=head4 Province

=over 

=item * CA 

Canadian Federal holidays (the default).

=item * AB

Alberta

=item * BC

British Columbia

=item * MB

Manitoba

=item * NB

New Brunswick

=item * NL

Newfoundland & Labrador

=item * NS

Nova Scotia

=item * NT

Northwest Territories

=item * NU

Nunavut

=item * ON

Ontario 

=item * PE

Prince Edward Island

=item * QC

Quebec

=item * SK

Saskatchewan

=item * YT

Yukon Territory

=back 

=head4 Language

=over 

=item * EN/FR

English text followed by French text.

=item * FR/EN

French text followed by English text.

=item * EN

English text only.

=item * FR

French text only.

=back

=cut 

 
sub new {
    my $class    = shift;
    my $args_ref = shift;
    
    my $self = {
        province => 'CA',
        language => 'EN/FR',
    };

    bless $self, $class;
    $self->set($args_ref);
    return $self; 
}



=head2 Object Methods

=head3 get()

Retrieve fields of a Date::Holidays::CA object.

    $prov = $dhc->('province');               

=cut

sub get {
    croak 'Wrong number of arguments to get()' if scalar @_ != 2;
    my $self  = shift;
    my $field = shift;
    
    if (exists $self->{$field}) {
        return $self->{$field};
    }

    croak "No such field $field";
}


=head3 set()

Alter fields of a Date::Holidays::CA object.  Specify parameters just
as with new(). 

    $dhc->set({province => 'QC', language => 'FR/EN'});               

=cut

sub set {
    croak 'Wrong number of arguments to set()' if scalar @_ != 2;
    my $self     = shift;
    my $args_ref = shift;
   
    while (my ($field, $value) = each %{$args_ref}) {
        my $new_value;

        if ($new_value = _validate($field, $value)) {
            $self->{$field} = $new_value;
        } 
    }

    return 1;
}


=head2 Combination Methods 

These methods are callable in either object-oriented or procedural style.  

=head3 is_holiday()

For a given year, month (1-12) and day (1-31), return 1 if the given
day is a holiday; 0 if not.  When using procedural calling style, an
additional hashref of options can be specified.

    $holiday_p = is_holiday($year, $month, $day);          

    $holiday_p = is_holiday($year, $month, $day, {
        province => 'BC', language => 'EN'
    });

    $holiday_p = $dhc->is_holiday($year, $month, $day);

=cut

sub is_holiday {
    return ( is_ca_holiday(@_) ? 1 : 0 );
}


=head3 is_ca_holiday()

Similar to C<is_holiday>.  Return the name of the holiday occurring on
the specified date if there is one; C<undef> if there isn't.

    print $dhc->is_ca_holiday(2001, 1, 1);          # "New Year's Day"

=cut

sub is_ca_holiday {
    my $self; 
    $self = shift if (ref $_[0]);               # invoked in OO style

    my $year    = shift;
    my $month   = shift;
    my $day     = shift;
    my $options = shift;

    _assert_valid_date($year, $month, $day);

    unless (defined $self) {
        $self = Date::Holidays::CA->new($options);
    }

    my $calendar = $self->_generate_calendar($year);

    # assumption: there is only one holiday for any given day. 
    while (my ($holiday_name, $holiday_dt) = each %$calendar) {
        if ($month == $holiday_dt->month and $day == $holiday_dt->day) {
            return $holiday_name;
        }
    }

    return;
}


=head3 is_holiday_dt()

As is_holiday, but accepts a DateTime object in place of a numeric year, 
month, and day.

    $holiday_p = is_holiday($dt, {province => 'SK', language => 'EN'});

    $holiday_p = $dhc->is_holiday($dt);

=cut 

sub is_holiday_dt {
    my ($self, $dt, $options); 

    my @args = map { 
        ref $_ eq 'DateTime' ? ($_->year, $_->month, $_->day) : $_ 
    } @_;

    return is_holiday(@args);
}


=head3 holidays()

For the given year, return a hashref containing all the holidays for 
that year.  The keys are the date of the holiday in C<mmdd> format 
(eg '1225' for December 25); the values are the holiday names. 

    my $calendar = holidays($year, {province => 'MB', language => 'EN'}); 
    print $calendar->('0701');               # "Canada Day"
    
    my $calendar = $dhc->holidays($year);
    print $calendar->('1111');               # "Remembrance Day"

=cut 

sub holidays {
    my $calendar = holidays_dt(@_);

    my %holidays = map {
       $calendar->{$_}->strftime('%m%d') => $_
    } keys %$calendar;

    return \%holidays;
}


=head3 ca_holidays()

Same as C<holidays()>.

=cut 

sub ca_holidays {
    return holidays(@_);
}


=head3 holidays_dt()

Similar to C<holidays()>, after a fashion: returns a hashref with the
holiday names as the keys and DateTime objects as the values.

    my $calendar = $dhc->holidays_dt($year);  

=cut

sub holidays_dt {
    my $self; 
    $self = shift if (ref $_[0]);               # invoked in OO style

    my $year     = shift;
    my $args_ref = shift;

    unless (defined $self) {
        $self = Date::Holidays::CA->new($args_ref);
    }

    return $self->_generate_calendar($year);
}



### internal functions 

my @VALID_PROVINCES = qw{ CA AB BC MB NB NL NS NT NU ON PE QC SK YT };
my @VALID_LANGUAGES = qw{ EN/FR FR/EN EN FR };
my %VALUES_FOR = (
    'PROVINCE' => \@VALID_PROVINCES,
    'LANGUAGE' => \@VALID_LANGUAGES,
);


# _validate($field, $value) 
#
# accepts: field name ( 'province' | 'language' ) 
#          possible value for that field
# returns: if $value is a valid value for $field, canonicalize and return
#          it (eg, upcase it).
#          if $value isn't valid, throw an exception.


sub _validate {
    my $field = shift;
    my $value = shift;

    my @valid_values = @{ $VALUES_FOR{uc($field)} };
    croak "No such field $field" unless @valid_values;

    foreach my $valid_value (@valid_values) {
        return uc($value) if uc($value) eq $valid_value;
    }

    croak "$value is not a recognized setting for $field";
}


# _assert_valid_date
# 
# accepts: numeric year, month, day
# returns: nothing 
#
# throw an exception on invalid dates; otherwise, do nothing.

sub _assert_valid_date {
    my ($year, $month, $day) = @_;

    # DateTime does date validation when a DT object is created.
    my $dt = DateTime->new(
        year => $year, month => $month, day => $day, 
    ); 
}


# format: each holiday is listed as a triplet:
#   * function that returns a DateTime object for that holiday
#   * english name
#   * french name
# listing the names each time makes for a verbose list with a lot of
# repetition; unfortunately different provinces sometimes call different
# holidays different things.

my %HOLIDAYS_FOR = (
    CA => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_easter_monday,            'Easter Monday', 'Lundi de Pâques',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],   
    
    AB => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_family_day,               'Family Day', 'Jour de la Famille',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Alberta Heritage Day', 'Jour d\'Héritage d\'Alberta',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    BC => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'BC Day', 'Fête de la Colombie-Britannique',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    MB => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_family_day,               'Louis Riel Day', 'Jour de Louis Riel',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Civic Holiday', 'Congé Statutaire',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    NB => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'New Brunswick Day', 'Fête du Nouveau-Brunswick',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    NL => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_st_patricks_day,          'St Patrick\'s Day', 'La Saint-Patrick',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_st_georges_day,           'St George\'s Day', 'La Saint-Georges',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_nl_discovery_day,         'Discovery Day', 'Jour de la Découverte',
            \&_canada_day,               'Memorial Day', 'Fête du Canada',
            \&_orangemens_day,           'Orangemen\'s Day', 'Fête des Orangistes',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],
    
    NS => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Natal Day', 'Jour de la Fondation',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    NT => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_national_aboriginal_day,  'National Aboriginal Day', 'Journée Nationale des Autochtones',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Civic Holiday', 'Congé Statutaire',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],
    
    NU => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Civic Holiday', 'Congé Statutaire',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],
    
    ON => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_family_day,               'Family Day', 'Jour de la Famille',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Civic Holiday', 'Congé Statutaire',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],
    
    PE => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_family_day,               'Islander Day', 'Fête des Insulaires',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Natal Day', 'Jour de la Fondation',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
            \&_boxing_day,               'Boxing Day', 'Lendemain de Noël',
    ],
    
    QC => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_easter_monday,            'Easter Monday', 'Lundi de Pâques',
            \&_victoria_day,             'Victoria Day', 'Journée Nationale des Patriotes / Fête de la Reine',
            \&_st_john_baptiste_day,     'Saint-Jean-Baptiste Day', 'La Saint-Jean',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    SK => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_family_day,               'Family Day', 'Jour de la Famille',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_civic_holiday,            'Saskatchewan Day', 'Fête de la Saskatchewan',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
    
    YT => [
            \&_new_years_day,            'New Year\'s Day', 'Jour de l\'An',
            \&_good_friday,              'Good Friday', 'Vendredi Saint',
            \&_victoria_day,             'Victoria Day', 'Fête de la Reine',
            \&_canada_day,               'Canada Day', 'Fête du Canada',
            \&_yt_discovery_day,         'Discovery Day', 'Jour du découverte',
            \&_labour_day,               'Labour Day', 'Fête du Travail',
            \&_thanksgiving_day,         'Thanksgiving Day', 'Action de Grâce',
            \&_remembrance_day,          'Remembrance Day', 'Jour du Souvenir',
            \&_christmas_day,            'Christmas Day', 'Noël',
    ],
);


# _generate_calendar
#
# accepts: numeric year
# returns: hashref (string $holiday_name => DateTime $holiday_dt)
# 
# generate a holiday calendar for the specified year -- a hash mapping
# holiday names to datetime objects.
sub _generate_calendar { 
    my $self = shift;
    my $year = shift; 
    my $calendar = {}; 

    my @holiday_list = @{ $HOLIDAYS_FOR{$self->{'province'}} };

    while(@holiday_list) {
        my $holiday_dt = (shift @holiday_list)->($year);  # fn invokation 
        my $name_en    = shift @holiday_list;
        my $name_fr    = shift @holiday_list;

        my $holiday_name = 
              $self->{'language'} eq 'EN'    ? $name_en  
            : $self->{'language'} eq 'FR'    ? $name_fr 
            : $self->{'language'} eq 'EN/FR' ? "$name_en/$name_fr" 
            : $self->{'language'} eq 'FR/EN' ? "$name_fr/$name_en"  
            : "$name_en/$name_fr";  # sane default, should never get here

        $calendar->{$holiday_name} = $holiday_dt;
    }

    return $calendar;
}

### toolkit functions 

# _nth_monday
#
# accepts:  year, month, ordinal of which monday to find 
# returns:  numeric date of the requested monday
#
# find the day of week for the first day of the month, 
# calculate the number of day to skip forward to hit the first monday, 
# then skip forward the requisite number of weeks.
#
# in general, the number of days we need to skip forward from the 
# first of the month is (target_dow - first_of_month_dow) % 7

sub _nth_monday {
    my $year  = shift;
    my $month = shift;
    my $n     = shift;

    my $first_of_month = DateTime->new( 
        year  => $year,
        month => $month,
        day   => 1,
    ); 

    my $date_of_first_monday = 1 + ( (1 - $first_of_month->dow()) % 7);

    return $date_of_first_monday + 7 * ($n - 1);
}

# _nearest_monday
#
# accepts:  year, month, day for a given date  
# returns:  day of the nearest monday to that date

sub _nearest_monday {
    my $year  = shift;
    my $month = shift;
    my $day   = shift;

    my $dt = DateTime->new(year => $year, month => $month, day => $day); 
    
    my $delta_days = ((4 - $dt->dow) % 7) - 3;

    return $day + $delta_days;
}

### holiday date calculating functions 
#
# these all take one parameter ($year) and return a DateTime object 
# specifying the day of the holiday for that year.

sub _new_years_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 1,
        day   => 1,
    ); 
}

sub _family_day {  
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 2,
        day   => _nth_monday($year, 2, 3),
    ); 
}

sub _st_patricks_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 2,
        day   => _nearest_monday($year, 3, 17),
    ); 
}

sub _good_friday {
    my $year = shift;

    my $dt = DateTime->new( year => $year, month => 1, day => 1 );
    my $event = DateTime::Event::Easter->new(day => 'Good Friday');
    return $event->following($dt);
}

sub _easter_sunday {
    my $year = shift;
     
    my $dt = DateTime->new( year => $year, month => 1, day => 1 );
    my $event = DateTime::Event::Easter->new(day => 'Easter Sunday');
    return $event->following($dt);
}

sub _easter_monday {
    my $year = shift;

    my $dt = DateTime->new( year => $year, month => 1, day => 1 );
    my $event = DateTime::Event::Easter->new(day => +1);
    return $event->following($dt);
}

sub _st_georges_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 4,
        day   => _nearest_monday($year, 4, 23),
    ); 
}

sub _victoria_day {
    my $year = shift;

    my $may_24 = DateTime->new( 
        year  => $year,
        month => 5,
        day   => 24,
    );

    return DateTime->new( 
        year  => $year,
        month => 5,
        day   => 25 - $may_24->dow()
    );
}

sub _national_aboriginal_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 6,
        day   => 21,
    ); 
}

sub _st_john_baptiste_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 6,
        day   => 24,
    ); 
} 

sub _nl_discovery_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 6,
        day   => _nearest_monday($year, 6, 24),
    ); 
}

sub _canada_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 7,
        day   => 1,
    );
}

sub _nunavut_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 7,
        day   => 9,
    );
}

sub _orangemens_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 7,
        day   => _nearest_monday($year, 7, 12),
    ); 
}

sub _civic_holiday {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 8,
        day   => _nth_monday($year, 8, 1),
    ); 
}

sub _yt_discovery_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 8,
        day   => _nth_monday($year, 8, 3),
    ); 
}

sub _labour_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 9,
        day   => _nth_monday($year, 9, 1),
    ); 
}

sub _thanksgiving_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 10,
        day   => _nth_monday($year, 10, 2),
    ); 
}

sub _remembrance_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 11,
        day   => 11,
    );
}

sub _christmas_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 12,
        day   => 25,
    );
}

sub _boxing_day {
    my $year = shift;

    return DateTime->new( 
        year  => $year,
        month => 12,
        day   => 26,
    );
}


1;  # all's well

__END__


=head1 SPECIFICATIONS 

The following holidays are recognized:

=over

=item I<New Year's Day>

January 1.

=item I<Islander Day>

PE.  Originally added in 2009 as the second Monday in February, this 
holiday will be revised to the third Monday in February starting in
2010.  I<This module shows Islander Day as falling on the third Monday>
-- see the I<KNOWN BUGS> section.

=item I<Family Day / Louis Riel Day>

The Third Monday of February is Family Day in AB, SK, and ON, and
Louis Riel Day in MB.

=item I<St. Patrick's Day>

NL.  Nearest Monday to March 17.

=item I<Good Friday>

The Friday falling before Easter Sunday.

=item I<Easter Monday>

CA, QC.  The Monday following Easter Sunday.

=item I<St. Patrick's Day>

NL.  Nearest Monday to April 23.

=item I<Victoria Day>

Monday falling on or before May 24.

=item I<National Aboriginal Day>

NT.  June 21.

=item I<Saint-Jean-Baptiste Day>

QC.  June 24.

=item I<Discovery Day>

There are actually two holidays named "Discovery Day".  Newfoundland observes
Discovery Day on the Monday nearest June 24, and the Yukon observes Discovery
Day on the third Monday of August.

=item I<Canada Day>

July 1.

=item I<Nunavut Day>

NU.  July 9.

=item I<Orangemen's Day>

NL.  Monday nearest July 12.

=item I<Civic Holiday>

AB, BC, MB, NB, NS, NT, NU, ON, PE, SK (that is to say, not CA, NL, QC, or YT).
First Monday of August.

Different provinces call this holiday different things -- eg "BC Day" in
British Columbia, "Alberta Heritage Day" in Alberta, "Natal Day" in 
Nova Scotia and PEI, and so forth.

=item I<Labour Day>

First Monday of September.

=item I<Thanksgiving Day>

Second Monday of October.

=item I<Remembrance Day>

All but ON and QC.  November 11. 

=item I<Christmas Day>

December 25.

=item I<Boxing Day>

CA, NL, NT, NU, ON, PE.  December 26.

=back

=head1 REFERENCES

L<http://en.wikipedia.org/wiki/Public_holidays_in_Canada>

L<http://www.craigmarlatt.com/canada/symbols_facts&lists/holidays.html>

L<http://www.craigmarlatt.com/canada/symbols_facts&lists/august_holiday.html>

L<http://geonames.nrcan.gc.ca/info/prov_abr_e.php> (Provincial abbreviations)

A grillion government web pages listing official statutory holidays, all of
which seem to have gone offline or moved.

L<http://www.gov.mb.ca/labour/standards/doc,louis-riel_day,factsheet.html> (MB's Louis Riel Day)

L<http://www.theguardian.pe.ca/index.cfm?sid=244766&sc=98> (PEI's Islander Day) 

=head1 KNOWN BUGS

B<Historical holidays are not supported>; the current set of holidays
will be projected into the past or future.  For instance, Louis Riel Day
was added as a Manitoba holiday in 2008, but if you use this module to
generate a holiday list for 2007, Louis Riel Day will be present. 
Also, PEI's Islander Day was first observed on the second Monday of 2009,
but will subsequently be observed on the third Monday of the month; this
module will always show it as occurring on the third Monday.
This will be addressed if there is demand to do so.

B<Several lesser holidays are not yet implemented>:

=over

=item I<Calgary Stampede>

I am told that the morning of the Stampede Parade is commonly given as 
a half-day holiday by employers within the city of Calgary, but I
haven't been able to verify this, nor does there seem to be a way to 
mathematically calculate when parade day will be scheduled.

=item I<St Johns Regatta Day>

Regatta Day is a municipal holiday in St Johns, NL, and it is scheduled for
the first Wednesday in August.  However, if the weather on Quidi Vidi Lake
does not look promising on Regatta morning, the event I<(and the attendant
holiday)> are postponed until the next suitable day.

How to programatically determine the day of this holiday has not yet been
satisfactorily ascertained.  L<Acme::Test::Weather|Acme::Test::Weather> 
has been considered.

=item I<Gold Cup and Saucer Day (PEI)>

Some few employees apparently get the day of the Gold Cup and Saucer
harness race as a holiday, but I haven't been able to independently
verify this.

=item I<Construction Holiday (Quebec)>

In Quebec, the vast majority of the construction industry gets the last
full two weeks of July off, and it's also a popular time for other folks
to book vacation.  Since this technically only applies to a single
industry, I haven't added it to this module, but I will if there is
sufficient demand.  

=back

=head1 HELP WANTED

As you can see from the I<KNOWN BUGS> section above, our holiday structure
can be fairly baroque.  Different provinces and cities get different
holidays; sometimes these are paid statutory holidays that are
included in Employment Standards legislation; other times they are 
unofficial holidays that are given by convention and codified only in 
collective agreements and municipal by-laws.  Thus, it's hard to know
what's commonly considered "a holiday" in the various regions of the
country without actually having lived and worked there.

I only have direct experience with British Columbia and Ontario; my
impression of what folks in other provinces consider to be a holiday
is based on research on the WWW.  I've tried to define a holiday as 
any day when "the majority of the workforce either get the day off
(paid or unpaid) or receive pay in lieu."  If the holidays list in this
module doesn't accurately reflect the application of that definition
to your region of Canada, I'd like to hear about it.

Assistance with French translations of the holiday names and this
documentation is most welcome.  My French isn't all that great,
but I'm happy to learn.  =)

Finally, I'd appreciate an email from any users of this module.  
I'm curious to know who has picked it up, and any feedback you might
have will shape its future development. 

=head1 CAVEATS

For reasons outlined in the two sections above, please be forewarned
that what days are considered holidays may change with versions of
the module.

=head1 AUTHOR

Rick Scott <rick@cpan.org>

=head1 SEE ALSO

=over

=item Date::Holidays

=item DateTime

=item DateTime::Event::Easter

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Rick Scott

This module is free software!  You can copy, modify, share and
distribute it under the same license as Perl itself.

=cut
