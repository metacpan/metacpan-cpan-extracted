package Convert::Pluggable;

use Moo;

use File::Slurp qw/read_file/;

use Data::Float qw/float_is_infinite float_is_nan/;
use Scalar::Util qw/looks_like_number/;

use JSON;
use Switch;

our @EXPORT_OK = qw(convert get_units);

our $VERSION           = '0.0322';
our $DEFAULT_PRECISION = 3;

has data_file => ( is => 'lazy', );

has types => ( is => 'lazy', );

sub temperature_get_factor {
    my $convert = shift;

    switch ( $convert->{'from_unit'} ) {
        case /^(fahrenheit|f)$/i { return $convert->{'factor'}; }
        case /^(celsius|c)$/i {
            return ( $convert->{'factor'} * ( 9 / 5 ) ) + 32;
        }
        case /^(kelvin|k)$/i {
            return ( $convert->{'factor'} * ( 9 / 5 ) ) - 459.67;
        }
        case /^(rankine|r)$/i { return ( $convert->{'factor'} - 491.67 ) + 32; }
        case /^(reaumur|re)$/i {
            return ( $convert->{'factor'} * ( 9 / 4 ) ) + 32;
        }
        else { return undef; }
    }
}

sub convert_temperatures {
    my $convert = shift;

    # convert $from to fahrenheit:
    my $factor = temperature_get_factor($convert);

    # convert fahrenheit $to:
    switch ( $convert->{'to_unit'} ) {
        case /^(fahrenheit|f)$/i { return $factor; }
        case /^(celsius|c)$/i    { return ( $factor - 32 ) * ( 5 / 9 ); }
        case /^(kelvin|k)$/i     { return ( $factor + 459.67 ) * ( 5 / 9 ); }
        case /^(rankine|r)$/i    { return $factor + 459.67; }
        case /^(reaumur|re)$/i   { return ( $factor - 32 ) * ( 4 / 9 ); }
        else                     { return undef; }
    }
}

sub get_matches {
    my $self    = shift;
    my $matches = shift;

    my @matches = @{$matches};

    $matches[0] =~ s/"/inches/;
    $matches[0] =~ s/'/feet/;
    $matches[1] =~ s/"/inches/;
    $matches[1] =~ s/'/feet/;

    my @match_types     = ();
    my @factors         = ();
    my @units           = ();
    my @can_be_negative = ();

    my @types = @{ get_units() };

    foreach my $match (@matches) {
        foreach my $type ( @{ $self->types } ) {
            if ( lc $match eq $type->{'unit'}
                || grep { $_ eq lc $match } @{ $type->{'aliases'} } )
            {
                push( @match_types,     $type->{'type'} );
                push( @factors,         $type->{'factor'} );
                push( @units,           $type->{'unit'} );
                push( @can_be_negative, $type->{'can_be_negative'} || '0' );
            }
        }
    }

    return if scalar(@match_types) != 2;
    return if scalar(@factors) != 2;
    return if scalar(@units) != 2;
    return if scalar(@can_be_negative) != 2;

    my %matches = (
        'type_1'            => $match_types[0],
        'type_2'            => $match_types[1],
        'factor_1'          => $factors[0],
        'factor_2'          => $factors[1],
        'from_unit'         => $units[0],
        'to_unit'           => $units[1],
        'can_be_negative_1' => $can_be_negative[0],
        'can_be_negative_2' => $can_be_negative[1],
    );

    return \%matches;
}

sub convert {
    my $self = shift;

    my $conversion = shift;
    my $matches    = get_matches( $self,
        [ $conversion->{'from_unit'}, $conversion->{'to_unit'} ] );

    return
      if !( $matches->{'type_1'} && $matches->{'type_2'} );

    if ( looks_like_number( $conversion->{'factor'} ) ) {

        # looks_like_number thinks 'Inf' and 'NaN' are numbers:
        return
          if float_is_infinite( $conversion->{'factor'} )
          || float_is_nan( $conversion->{'factor'} );

        # if factor is < 0 and first thing can't be negative ...
        return
          if $conversion->{'factor'} < 0 && !$matches->{'can_be_negative_1'};
    }
    else {
     # if it doesn't look like a number, and it contains a number (e.g., '6^2'):
        $conversion->{'factor'} = parse_number( $conversion->{'factor'} );
    }

    return if $conversion->{'factor'} =~ /[[:alpha:]]/;

    # matches must be of the same type (e.g., can't convert mass to length):
    return if ( $matches->{'type_1'} ne $matches->{'type_2'} );

    # run the conversion:
    # temperatures don't have 1:1 conversions, so they get special treatment:
    my $factor;
    if ( $matches->{'type_1'} eq 'temperature' ) {
        $factor = convert_temperatures(
            {
                from_unit => $matches->{'from_unit'},
                to_unit   => $matches->{'to_unit'},
                factor    => $conversion->{'factor'},
            }
        );
    }
    else {
        $factor = $conversion->{'factor'} *
          ( $matches->{'factor_2'} / $matches->{'factor_1'} );
    }

    return if $factor < 0 && !( $matches->{'can_be_negative_2'} );

    $matches->{'result'} = precision(
        {
            factor    => $factor,
            precision => $conversion->{'precision'} || $DEFAULT_PRECISION,
        }
    );

    return $matches;
}

# thanks, @mwmiller!
sub parse_number {
    my $in = shift;

    my $out =
      ( $in =~ /^(-?\d*(?:\.?\d+))\^(-?\d*(?:\.?\d+))$/ ) ? $1**$2 : $in;

    return $in if $out =~ /[^\d]/;    # elo

    return 0 + $out;
}

sub _build_types {
    my $self = shift;

    return get_units( $self->{data_file} );
}

sub get_units {
    my $self = shift;

    #my $data_file = shift // 'NO_DATA_FILE';
    my $data_file = defined(shift) ? shift : 'NO_DATA_FILE';

    my $units;

    if ( $data_file eq 'NO_DATA_FILE' ) {

        $units = encode_json( old_get_units() );

    }
    else {
        $units = read_file($data_file);
    }

    return decode_json($units);
}

# does it make sense to return X if precision is > 1?
#   e.g., result = '0.999' with precision = '3' returns '1' atm
#   e.g., result = '1.000' with precision = '3' returns '1' atm
sub precision {
    my $precision = shift;

    if ( $precision->{'factor'} == 0 ) { return 0; }

    my $f = $precision->{'factor'} * ( 10**$precision->{'precision'} );

    my $r = int( $f + $f / abs( $f * 2 ) );

    return $r / ( 10**$precision->{'precision'} );
}

sub old_get_units {

    # metric ton is base unit for mass
    # known SI units and aliases / plurals
    my @mass = (
        {
            'unit'    => 'metric ton',
            'factor'  => '1',
            'aliases' => [
                'tonne',       't',      'mt', 'te',
                'metric tons', 'tonnes', 'ts', 'mts',
                'tes'
            ],
            'type' => 'mass',
        },
        {
            'unit'    => 'ounce',
            'factor'  => '35274',
            'aliases' => [ 'oz', 'ounces', 'ozs' ],
            'type'    => 'mass',
        },
        {
            'unit'    => 'pound',
            'factor'  => '2204.62',
            'aliases' => [
                'lb',  'lbm',  'pound mass', 'pounds',
                'lbs', 'lbms', 'pounds mass'
            ],
            'type' => 'mass',
        },
        {
            'unit'    => 'stone',
            'factor'  => '157.473',
            'aliases' => [ 'st', 'stones', 'sts' ],
            'type'    => 'mass',
        },
        {
            'unit'    => 'long ton',
            'factor'  => '0.984207',
            'aliases' => [
                'weight ton',
                'imperial ton',
                'long tons',
                'weight tons',
                'imperial tons'
            ],
            'type' => 'mass',
        },
        {
            'unit'    => 'microgram',
            'factor'  => 1_000_000_000_000,
            'aliases' => [ 'mcg', 'micrograms', 'mcgs' ],
            'type'    => 'mass',
        },
        {
            'unit'    => 'kilogram',
            'factor'  => 1000,
            'aliases' => [
                'kg',  'kilo',  'kilogramme', 'kilograms',
                'kgs', 'kilos', 'kilogrammes'
            ],
            'type' => 'mass',
        },
        {
            'unit'   => 'gram',
            'factor' => 1_000_000,
            'aliases' =>
              [ 'g', 'gm', 'gramme', 'grams', 'gs', 'gms', 'grammes' ],
            'type' => 'mass',
        },
        {
            'unit'    => 'milligram',
            'factor'  => 1_000_000_000,
            'aliases' => [ 'mg', 'milligrams', 'mgs' ],
            'type'    => 'mass',
        },
        {
            'unit'    => 'ton',
            'factor'  => '1.10231',
            'aliases' => [ 'short ton', 'short tons', 'tons' ],
            'type'    => 'mass',
        },
    );

    # meter is the base unit for length
    # known SI units and aliases / plurals
    my @length = (
        {
            'unit'    => 'meter',
            'factor'  => '1',
            'aliases' => [ 'meters', 'metre', 'metres', 'm' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'kilometer',
            'factor'  => '0.001',
            'aliases' => [
                'kilometers', 'kilometre', 'kilometres', 'km',
                'kms',        'klick',     'klicks'
            ],
            'type' => 'length',
        },
        {
            'unit'   => 'centimeter',
            'factor' => '100',
            'aliases' =>
              [ 'centimeters', 'centimetre', 'centimetres', 'cm', 'cms' ],
            'type' => 'length',
        },
        {
            'unit'   => 'millimeter',
            'factor' => '1000',
            'aliases' =>
              [ 'millimeters', 'millimetre', 'millimetres', 'mm', 'mms' ],
            'type' => 'length',
        },
        {
            'unit'    => 'mile',
            'factor'  => 1 / 1609.344,
            'aliases' => [
                'miles',
                'statute mile',
                'statute miles',
                'land mile',
                'land miles',
                'mi'
            ],
            'type' => 'length',
        },
        {
            'unit'    => 'yard',
            'factor'  => '1.0936133',
            'aliases' => [ 'yards', 'yd', 'yds', 'yrds', 'yrd' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'foot',
            'factor'  => '3.28084',
            'aliases' => [
                'feet',
                'ft',
                'international foot',
                'international feet',
                'survey foot',
                'survey feet'
            ],
            'type' => 'length',
        },
        {
            'unit'    => 'inch',
            'factor'  => '39.3701',
            'aliases' => [ 'inches', 'in', 'ins' ],
            'type'    => 'length',
        },
        {
            'unit'   => 'nautical mile',
            'factor' => '0.000539957',
            'aliases' =>
              [ 'nautical miles', 'n', 'ns', 'nm', 'nms', 'nmi', 'nmis' ],
            'type' => 'length',
        },
        {
            'unit'    => 'furlong',
            'factor'  => ( 1 / 201.168 ),
            'aliases' => ['furlongs'],
            'type'    => 'length',
        },
        {
            'unit'    => 'chain',
            'factor'  => ( 1 / 20.1168 ),
            'aliases' => [ "gunter's chains", 'chains' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'link',
            'factor'  => ( 1 / 0.201168 ),
            'aliases' => [ "gunter's links", 'links' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'rod',
            'factor'  => 1 / (5.0292),
            'aliases' => ['rods'],
            'type'    => 'length',
        },
        {
            'unit'    => 'fathom',
            'factor'  => 1 / (1.853184),
            'aliases' => [ 'fathoms', 'ftm', 'ftms' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'league',
            'factor'  => 1 / (4828.032),
            'aliases' => ['leagues'],
            'type'    => 'length',
        },
        {
            'unit'    => 'cable',
            'factor'  => 1 / (185.3184),
            'aliases' => ['cables'],
            'type'    => 'length',
        },
        {
            'unit'    => 'light year',
            'factor'  => ( 1 / 9460730472580800 ),
            'aliases' => [ 'light years', 'ly', 'lys' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'parsec',
            'factor'  => ( 1 / 30856776376340067 ),
            'aliases' => [ 'parsecs', 'pc', 'pcs' ],
            'type'    => 'length',
        },
        {
            'unit'    => 'astronomical unit',
            'factor'  => ( 1 / 149597870700 ),
            'aliases' => [ 'astronomical units', 'au', 'aus' ],
            'type'    => 'length',
        },
    );

    # day is base unit for time
    # known SI units and aliases / plurals
    my @time = (
        {
            'unit'    => 'day',
            'factor'  => '1',
            'aliases' => [ 'days', 'dy', 'dys', 'd' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'second',
            'factor'  => '86400',
            'aliases' => [ 'seconds', 'sec', 's' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'millisecond',
            'factor'  => '86400000',
            'aliases' => [ 'milliseconds', 'millisec', 'millisecs', 'ms' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'microsecond',
            'factor'  => '86400000000',
            'aliases' => [ 'microseconds', 'microsec', 'microsecs', 'us' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'nanosecond',
            'factor'  => '86400000000000',
            'aliases' => [ 'nanoseconds', 'nanosec', 'nanosecs', 'ns' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'minute',
            'factor'  => '1440',
            'aliases' => [ 'minutes', 'min', 'mins' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'hour',
            'factor'  => '24',
            'aliases' => [ 'hours', 'hr', 'hrs', 'h' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'week',
            'factor'  => 1 / 7,
            'aliases' => [ 'weeks', 'wks', 'wk' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'fortnight',
            'factor'  => 1 / 14,
            'aliases' => [],
            'type'    => 'duration',
        },
        {
            'unit'    => 'month',
            'factor'  => 12 / 365,
            'aliases' => [ 'months', 'mons', 'mns', 'mn' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'year',
            'factor'  => 1 / 365,
            'aliases' => [ 'years', 'yr', 'yrs' ],
            'type'    => 'duration',
        },
        {
            'unit'    => 'leap year',
            'factor'  => 1 / 366,
            'aliases' => [ 'leap years', 'leapyear', 'leapyr', 'leapyrs' ],
            'type'    => 'duration',
        },
    );

    # pascal is base unit for pressure
    # known SI units and aliases / plurals
    my @pressure = (
        {
            'unit'    => 'pascal',
            'factor'  => 1,
            'aliases' => [ 'pascals', 'pa', 'pas' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'kilopascal',
            'factor'  => ( 1 / 1000 ),
            'aliases' => [ 'kilopascals', 'kpa', 'kpas' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'megapascal',
            'factor'  => ( 1 / 1_000_000 ),
            'aliases' => [ 'megapascals', 'megapa', 'megapas' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'gigapascal',
            'factor'  => ( 1 / 1_000_000_000 ),
            'aliases' => [ 'gigapascals', 'gpa', 'gpas' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'bar',
            'factor'  => 1 / (100_000),
            'aliases' => [ 'bars', 'pa', 'pas' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'atmosphere',
            'factor'  => 1 / (101_325),
            'aliases' => [ 'atmospheres', 'atm', 'atms' ],
            'type'    => 'pressure',
        },
        {
            'unit'    => 'pounds per square inch',
            'factor'  => 1 / 6894.8,
            'aliases' => [ 'psis', 'psi', 'lbs/inch^2', 'p.s.i.', 'p.s.i' ],
            'type'    => 'pressure',
        },
    );

    # joule is base unit for energy
    # known SI units and aliases / plurals
    my @energy = (
        {
            'unit'    => 'joule',
            'factor'  => 1,
            'aliases' => [ 'joules', 'j', 'js' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'watt-second',
            'factor'  => (1),
            'aliases' => [ 'watt second', 'watt seconds', 'ws' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'watt-hour',
            'factor'  => ( 1 / 3600 ),
            'aliases' => [ 'watt hour', 'watt hours', 'wh' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'kilowatt-hour',
            'factor'  => ( 1 / 3_600_000 ),
            'aliases' => [ 'kilowatt hour', 'kilowatt hours', 'kwh' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'erg',
            'factor'  => ( 1 / 10_000_000 ),
            'aliases' => [ 'ergon', 'ergs', 'ergons' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'electron volt',
            'factor'  => (6.2415096e+18),
            'aliases' => [ 'electronvolt', 'electron volts', 'ev', 'evs' ],
            'type'    => 'energy',
        },
        {
            'unit'    => 'thermochemical gram calorie',
            'factor'  => ( 1 / 4.184 ),
            'aliases' => [
                'small calories',
                'thermochemical gram calories',
                'chemical calorie',
                'chemical calories'
            ],
            'type' => 'energy',
        },
        {
            'unit'    => 'large calorie',
            'factor'  => ( 1 / 4184 ),
            'aliases' => [
                'large calories',
                'food calorie',
                'food calories',
                'kcals',
                'kcal'
            ],
            'type' => 'energy',
        },
        {
            'unit'    => 'british thermal unit',
            'factor'  => ( 1 / 1054.5 ),
            'aliases' => [ 'british thermal units', 'btu', 'btus' ],
            'type'    => 'energy',
        },
        {
            'unit'   => 'ton of TNT',
            'factor' => ( 1 / 4.184e+9 ),
            'aliases' =>
              [ 'tnt equivilent', 'tonnes of tnt', 'tnt', 'tons of tnt' ],
            'type' => 'energy',
        }
    );

    # watt is base unit for power
    # known SI units and aliases / plurals
    my @power = (
        {
            'unit'    => 'watt',
            'factor'  => 1,
            'aliases' => [ 'watts', 'w' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'kilowatt',
            'factor'  => 1 / 1000,
            'aliases' => [ 'kilowatts', 'kw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'megawatt',
            'factor'  => 1 / 1_000_000,
            'aliases' => [ 'megawatts', 'mw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'gigawatt',
            'factor'  => 1 / 1_000_000_000,
            'aliases' => [ 'gigawatts', 'jiggawatts', 'gw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'terawatt',
            'factor'  => 1 / 1_000_000_000_000,
            'aliases' => [ 'terawatts', 'tw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'petawatt',
            'factor'  => 1 / 1_000_000_000_000_000,
            'aliases' => [ 'petawatts', 'pw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'milliwatt',
            'factor'  => 1000,
            'aliases' => ['milliwatts'],
            'type'    => 'power',
        },
        {
            'unit'    => 'microwatt',
            'factor'  => 1_000_000,
            'aliases' => ['microwatts'],
            'type'    => 'power',
        },
        {
            'unit'    => 'nanowatt',
            'factor'  => 1_000_000_000,
            'aliases' => [ 'nanowatts', 'nw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'picowatt',
            'factor'  => 1_000_000_000_000,
            'aliases' => [ 'picowatts', 'pw' ],
            'type'    => 'power',
        },
        {
            'unit'    => 'metric horsepower',
            'factor'  => ( 1 / 735.49875 ),
            'aliases' => [
                'metric horsepowers',
                'mhp', 'hp', 'ps', 'cv', 'hk', 'ks', 'ch'
            ],
            'type' => 'power',
        },
        {
            'unit'   => 'horsepower',
            'factor' => ( 1 / 745.69987158227022 ),
            'aliases' =>
              [ 'mechnical horsepower', 'horsepower', 'hp', 'hp', 'bhp' ],
            'type' => 'power',
        },
        {
            'unit'    => 'electical horsepower',
            'factor'  => ( 1 / 746 ),
            'aliases' => [ 'electical horsepowers', 'hp', 'hp' ],
            'type'    => 'power',
        },
    );

    # degree is base unit for angles
    # known SI units and aliases / plurals
    my @angle = (
        {
            'unit'    => 'degree',
            'factor'  => 1,
            'aliases' => [ 'degrees', 'deg', 'degs' ],
            'type'    => 'angle',
        },
        {
            'unit'    => 'radian',
            'factor'  => 3.14159265358979323 / 180,
            'aliases' => [ 'radians', 'rad', 'rads' ],
            'type'    => 'angle',
        },
        {
            'unit'   => 'gradian',
            'factor' => 10 / 9,
            'aliases' =>
              [ 'gradians', 'grad', 'grads', 'gon', 'gons', 'grade', 'grades' ],
            'type' => 'angle',
        },
        {
            'unit'    => 'quadrant',
            'factor'  => 1 / 90,
            'aliases' => [ 'quadrants', 'quads', 'quad' ],
            'type'    => 'angle',
        },
        {
            'unit'    => 'semi-circle',
            'factor'  => 1 / 180,
            'aliases' => [
                'semi circle', 'semicircle', 'semi circles', 'semicircles',
                'semi-circles'
            ],
            'type' => 'angle',
        },
        {
            'unit'    => 'revolution',
            'factor'  => 1 / 360,
            'aliases' => [ 'revolutions', 'circle', 'circles', 'revs' ],
            'type'    => 'angle',
        },
    );

    # newton is base unit for force
    # known SI units and aliases / plurals
    my @force = (
        {
            'unit'    => 'newton',
            'factor'  => 1,
            'aliases' => [ 'newtons', 'n' ],
            'type'    => 'force',
        },
        {
            'unit'    => 'kilonewton',
            'factor'  => 1 / 1000,
            'aliases' => [ 'kilonewtons', 'kn' ],
            'type'    => 'force',
        },
        {
            'unit'    => 'meganewton',
            'factor'  => 1 / 1_000_000,
            'aliases' => [ 'meganewtons', 'mn' ],
            'type'    => 'force',
        },
        {
            'unit'    => 'giganewton',
            'factor'  => 1 / 1_000_000_000,
            'aliases' => [ 'giganewtons', 'gn' ],
            'type'    => 'force',
        },
        {
            'unit'    => 'dyne',
            'factor'  => 1 / 100000,
            'aliases' => ['dynes'],
            'type'    => 'force',
        },
        {
            'unit'    => 'kilodyne',
            'factor'  => 1 / 100,
            'aliases' => ['kilodynes'],
            'type'    => 'force',
        },
        {
            'unit'    => 'megadyne',
            'factor'  => 10,
            'aliases' => ['megadynes'],
            'type'    => 'force',
        },
        {
            'unit'    => 'pounds force',
            'factor'  => 1 / 4.4482216152605,
            'aliases' => [ 'lbs force', 'pounds force' ],
            'type'    => 'force',
        },
        {
            'unit'    => 'poundal',
            'factor'  => 1 / 0.138254954376,
            'aliases' => [ 'poundals', 'pdl' ],
            'type'    => 'force',
        },
    );

    # fahrenheit is base unit for temperature
    # known SI units and aliases / plurals
    my @temperature = (
        {
            'unit'            => 'fahrenheit',
            'factor'          => 1,               # all '1' because un-used
            'aliases'         => ['f'],
            'type'            => 'temperature',
            'can_be_negative' => 1,
        },
        {
            'unit'            => 'celsius',
            'factor'          => 1,
            'aliases'         => ['c'],
            'type'            => 'temperature',
            'can_be_negative' => 1,
        },
        {
            'unit'    => 'kelvin',
            'factor'  => 1,
            'aliases' => ['k'],      # be careful ... other units could use 'K'
            'type' => 'temperature',
        },
        {
            'unit'    => 'rankine',
            'factor'  => 1,
            'aliases' => ['r'],
            'type'    => 'temperature',
        },
        {
            'unit'    => 'reaumur',
            'factor'  => 1,
            'aliases' => ['re']
            ,    # also can be 'R', but that's being used for rankine
            'type'            => 'temperature',
            'can_be_negative' => 1,
        },
    );

    # bit is base unit for digital
    # while not absolutely correct, a byte is defined as 8 bits herein.
    # known SI units and aliases / plurals
    my @digital = (
        {
            'unit'    => 'bit',
            'factor'  => 1,
            'aliases' => ['bits'],
            'type'    => 'digital',
        },
        {
            'unit'    => 'kilobit',
            'factor'  => 1 / 1_000,
            'aliases' => [ 'kbit', 'kbits', 'kilobits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'megabit',
            'factor'  => 1 / 1_000_000,
            'aliases' => [ 'mbit', 'mbits', 'megabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'gigabit',
            'factor'  => 1 / 1_000_000_000,
            'aliases' => [ 'gbit', 'gigabits', 'gbits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'terabit',
            'factor'  => 1 / 1_000_000_000_000,
            'aliases' => [ 'tbit', 'tbits', 'terabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'petabit',
            'factor'  => 1 / 1_000_000_000_000_000,
            'aliases' => [ 'pbit', 'pbits', 'petabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'exabit',
            'factor'  => 1 / 1_000_000_000_000_000_000,
            'aliases' => [ 'ebit', 'ebits', 'exabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'zettabit',
            'factor'  => 1 / 1_000_000_000_000_000_000_000,
            'aliases' => [ 'zbit', 'zbits', 'zettabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'yottabit',
            'factor'  => 1 / 1_000_000_000_000_000_000_000_000,
            'aliases' => [ 'ybit', 'ybits', 'yottabits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'kibibit',
            'factor'  => 1 / 1024,
            'aliases' => [ 'kibit', 'kibits', 'kibibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'mebibit',
            'factor'  => 1 / 1024**2,
            'aliases' => [ 'mibit', 'mibits', 'mebibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'gibibit',
            'factor'  => 1 / 1024**3,
            'aliases' => [ 'gibit', 'gibits', 'gibibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'tebibit',
            'factor'  => 1 / 1024**4,
            'aliases' => [ 'tibit', 'tibits', 'tebibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'pebibit',
            'factor'  => 1 / 1024**5,
            'aliases' => [ 'pibit', 'pibits', 'pebibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'exbibit',
            'factor'  => 1 / 1024**6,
            'aliases' => [ 'eibit', 'eibits', 'exbibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'zebibit',
            'factor'  => 1 / 1024**7,
            'aliases' => [ 'zibit', 'zibits', 'zebibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'yobibit',
            'factor'  => 1 / 1024**8,
            'aliases' => [ 'yibit', 'yibits', 'yobibits' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'byte',
            'factor'  => 1 / 8,
            'aliases' => ['bytes'],
            'type'    => 'digital',
        },
        {
            'unit'    => 'kilobyte',
            'factor'  => 1 / 8_000,
            'aliases' => [ 'kb', 'kbs', 'kilobytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'megabyte',
            'factor'  => 1 / 8_000_000,
            'aliases' => [ 'mb', 'mbs', 'megabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'gigabyte',
            'factor'  => 1 / 8_000_000_000,
            'aliases' => [ 'gb', 'gbs', 'gigabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'terabyte',
            'factor'  => 1 / 8_000_000_000_000,
            'aliases' => [ 'tb', 'tbs', 'terabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'petabyte',
            'factor'  => 1 / 8_000_000_000_000_000,
            'aliases' => [ 'pb', 'pbs', 'petabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'exabyte',
            'factor'  => 1 / 8_000_000_000_000_000_000,
            'aliases' => [ 'eb', 'ebs', 'exabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'zettabyte',
            'factor'  => 1 / 8_000_000_000_000_000_000_000,
            'aliases' => [ 'zb', 'zbs', 'zettabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'yottabyte',
            'factor'  => 1 / 8_000_000_000_000_000_000_000_000,
            'aliases' => [ 'yb', 'ybs', 'yottabytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'kibibyte',
            'factor'  => 1 / 8192,
            'aliases' => [ 'kib', 'kibs', 'kibibytes' ],    # KB
            'type'    => 'digital',
        },
        {
            'unit'    => 'mebibyte',
            'factor'  => 1 / 8388608,
            'aliases' => [ 'mib', 'mibs', 'mebibytes' ],    # MB
            'type'    => 'digital',
        },
        {
            'unit'    => 'gibibyte',
            'factor'  => 1 / 8589934592,                    # 1/8*1024**3 ...
            'aliases' => [ 'gib', 'gibs', 'gibibytes' ],    # GB ...
            'type'    => 'digital',
        },
        {
            'unit'    => 'tebibyte',
            'factor'  => 1 / 8796093022208,
            'aliases' => [ 'tib', 'tibs', 'tebibytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'pebibyte',
            'factor'  => 1 / 9007199254740992,              # 1/8*1024**5 ...
            'aliases' => [ 'pib', 'pibs', 'pebibytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'exbibyte',
            'factor'  => 1 / 9.22337203685478e+18,
            'aliases' => [ 'eib', 'eibs', 'exbibytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'zebibyte',
            'factor'  => 1 / 9.44473296573929e+21,
            'aliases' => [ 'zib', 'zibs', 'zebibytes' ],
            'type'    => 'digital',
        },
        {
            'unit'    => 'yobibyte',
            'factor'  => 1 / 9.67140655691703e+24,
            'aliases' => [ 'yib', 'yibs', 'yobibytes' ],
            'type'    => 'digital',
        },
    );

    # hectare is base unit for area
    my @area = (
        {
            'unit'    => 'hectare',
            'factor'  => 1,
            'aliases' => [ 'hectares', 'ha' ],
            'type'    => 'area',
        },
        {
            'unit'    => 'acre',
            'factor'  => 2.4710439,
            'aliases' => ['acres'],
            'type'    => 'area',
        },
        {
            'unit'    => 'square meter',
            'factor'  => 10_000,
            'aliases' => [
                'square meters', 'metre^2',
                'meter^2',       'metres^2',
                'meters^2',      'square metre',
                'square metres', 'm^2'
            ],
            'type' => 'area',
        },
        {
            'unit'    => 'square kilometer',
            'factor'  => 0.01,
            'aliases' => [
                'square kilometers',
                'square kilometre',
                'square kilometres',
                'km^2'
            ],
            'type' => 'area',
        },
        {
            'unit'    => 'square centimeter',
            'factor'  => 100_000_000,
            'aliases' => [
                'square centimeters',
                'square centimetre',
                'square centimetres',
                'cm^2'
            ],
            'type' => 'area',
        },
        {
            'unit'    => 'square millimeter',
            'factor'  => 10_000_000_000,
            'aliases' => [
                'square millimeters',
                'square millimetre',
                'square millimetres',
                'mm^2'
            ],
            'type' => 'area',
        },
        {
            'unit'    => 'square mile',
            'factor'  => 1 / 258.99881,
            'aliases' => [
                'square miles',
                'square statute mile',
                'square statute miles',
                'square land mile',
                'square land miles',
                'miles^2',
                'sq mi'
            ],
            'type' => 'area',
        },
        {
            'unit'   => 'square yard',
            'factor' => 11959.9,
            'aliases' =>
              [ 'square yards', 'yard^2', 'yards^2', 'yd^2', 'yrd^2' ],
            'type' => 'area',
        },
        {
            'unit'    => 'square foot',
            'factor'  => 107639.1,
            'aliases' => [ 'square feet', 'feet^2', 'foot^2', 'foot', 'ft^2' ],
            'type'    => 'area',
        },
        {
            'unit'   => 'square inch',
            'factor' => 15500031,
            'aliases' =>
              [ 'square inches', 'inch^2', 'inches^2', 'squinch', 'in^2' ],
            'type' => 'area',
        },
        {
            'unit'    => 'tsubo',
            'factor'  => 3024.9863876,
            'aliases' => ['tsubos'],
            'type'    => 'area',
        }
    );

    # litre is the base unit for volume
    my @volume = (
        {
            'unit'   => 'litre',
            'factor' => 1,
            'aliases' =>
              [ 'liter', 'litres', 'liters', 'l', 'litter', 'litters' ],
            'type' => 'volume',
        },
        {
            'unit'    => 'millilitre',
            'factor'  => 1000,
            'aliases' => [ 'milliliter', 'millilitres', 'milliliters', 'ml' ],
            'type'    => 'volume',
        },
        {
            'unit'   => 'cubic metre',
            'factor' => 1 / 1000,
            'aliases' =>
              [ 'metre^3', 'meter^3', 'metres^3', 'meters^3', 'm^3' ],
            'type' => 'volume',
        },
        {
            'unit'    => 'cubic centimetre',
            'factor'  => 1000,
            'aliases' => [
                'centimetre^3',  'centimeter^3',
                'centimetres^3', 'centimeters^3',
                'cm^3'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'cubic millimetre',
            'factor'  => 1_000_000,
            'aliases' => [
                'millimetre^3',  'millimeter^3',
                'millimetres^3', 'millimeters^3',
                'mm^3'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'liquid pint',
            'factor'  => 1000 / 473.176473,
            'aliases' => [
                'liquid pints',
                'us pints',
                'us liquid pint',
                'us liquid pints'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'dry pint',
            'factor'  => 1000 / 550.6104713575,
            'aliases' => ['dry pints'],
            'type'    => 'volume',
        },
        {
            'unit'    => 'imperial pint',
            'factor'  => 1000 / 568.26125,
            'aliases' => [
                'pints',        'pint', 'imperial pints', 'uk pint',
                'british pint', 'pts'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'imperial gallon',
            'factor'  => 1 / 4.54609,
            'aliases' => [
                'imperial gallon',
                'uk gallon',
                'british gallon',
                'british gallons',
                'uk gallons'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'us gallon',
            'factor'  => 1 / 3.78541178,
            'aliases' => [
                'fluid gallon',
                'us fluid gallon',
                'fluid gallons',
                'us gallons',
                'gallon',
                'gallons'
            ],
            'type' => 'volume',
        },
        {
            'unit'    => 'quart',
            'factor'  => 1 / 0.946352946,
            'aliases' => [
                'liquid quart',
                'us quart',
                'us quarts',
                'quarts',
                'liquid quarts'
            ],
            'type' => 'volume',
        },
        {
            'unit'   => 'imperial quart',
            'factor' => 4 * 1000 / 568.26125,
            'aliases' =>
              [ 'imperial quarts', 'british quarts', 'british quart' ],
            'type' => 'volume',
        },
        {
            'unit'    => 'imperial fluid ounce',
            'factor'  => 16 * 1000 / 568.26125,
            'aliases' => [
                'imperial fluid ounces',
                'imperial fl oz',
                'imperial fluid oz',
            ],
            'type' => 'volume',
        },
        {
            'unit'   => 'us fluid ounce',
            'factor' => 16 * 1000 / 473.176473,
            'aliases' =>
              [ 'us fluid ounces', 'us fl oz', 'fl oz', 'fl. oz', 'fluid oz' ],
            'type' => 'volume',
        },
        {
            'unit'    => 'us cup',
            'factor'  => 4.2267528,
            'aliases' => [ 'us cups', 'cups', 'cup' ],
            'type'    => 'volume',
        },
        {
            'unit'    => 'metric cup',
            'factor'  => 4,
            'aliases' => ['metric cups'],
            'type'    => 'volume',
        },
    );

    # unit types available for conversion
    my @types = (
        @mass,  @length,   @area,        @volume,
        @time,  @pressure, @energy,      @power,
        @angle, @force,    @temperature, @digital
    );

    return \@types;
}

1;

__END__
=head1 NAME

Convert::Pluggable - convert between various units of measurement

=head1 VERSION

Version 0.0322

Authoritative version is always here: L<https://github.com/elohmrow/Convert-Pluggable>

=head1 SYNOPSIS

convert between various units of measurement

=head1 IMPORTANT NOTICE - FUNCTIONALITY ADDITION 

You my use this module standalone prior to v0.031; there the units are all hard-coded into the module:

        use Convert::Pluggable;
        my $c = new Convert::Pluggable()
        my $c->convert( { 'factor' => '5', 'from_unit' => 'feet', 'to_unit' => 'inches', 'precision' => '3', });

Starting in v0.031 you may still use this module stand-alone, but you may optionally provide as a constructor argument 
the name of a data file (currently only supports JSON) - then you will be able to use C::P as a service.  See examples/service.pl 
for an example Dancer2 script.  See data/units.json for an example of a valid json data set. 

See t/Convert-Pluggable.t for many more example uses.

See L<https://ddh5.duckduckgo.com/?q=10000+minutes+in+microseconds> for examples of test uses

See L<https://github.com/elohmrow/Convert-Pluggable> for the most recent version

=head1 EXPORT

=head2 convert()

=head2 get_units()

=head1 SUBROUTINES/METHODS

=head2 new()

Create a new Conversion object.

=head2 new('/path/to/some/data.json')

Create a new Conversion object pre-loaded with serializable data to be used as a service.

=head2 convert_temperatures()

A function for converting between various temperature units.  Currently supports Fahrenheit, Celsius, Kelvin, Rankine, and Raumur.

=head2 convert()

This is the workhorse.  All conversion work (except for temperatures) gets done here.  This is an exported sub.

=head2 get_matches() 

=over 4

=item *

get factors for later calculating conversion

=item *

get trigger 'types' to determine if we can perform a calculation in the first place

=item *

get canoncial units for massaging output

=item *

determine if a unit may be negative 

This gets some useful metadata for convert() to carry out its work.

=back

=head2 get_units()

In versions prior to 0.031, this is where you add new unit types so that convert() can operate on them. This behavior is still supported.  This is an exported sub.  

Currently supported units of measurement are: mass, length, time, pressure, energy, power, angle, force, temperature, digital.

=head2 old_get_units()

If you don't pass in a data file on construction, units are gotten from a hardcoded hash in this source file.

=head2 parse_number()

handle numbers with special characters in them, like '6^2' and '2e3'.  written by mwmiller.

=head2 temperature_get_factor()

This sub handles converting any value for any temperature scale to the equivalent fahrenheit value for later conversion to some other unit.

=head2 precision()

This sub takes the output of a conversion and rounds it to the specified precision.  It is set by default to 3.

=head1 AUTHOR

bradley andersen, C<< <bradley at pvnp.us> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report / view bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert::Pluggable>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert::Pluggable/>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to @mintsoft and @jagtalon

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014-2016 Bradley Andersen. This program is free software; you may redistribute and/or modify it under the
same terms as Perl itself.

=head1 PRIOR ART - but not really!

Bot::BasicBot::Pluggable::Module::Convert relies on Math::Units

Convert::Temperature

=head1 TODO

=over 4

=item *

better error handling

=item *

all args to functions should be hash refs!
 
=item *

add more unit types (digital, cooking, roman numeral, etc.)

=item *

add main units to aliases (easier for searching with things like redis)

=item *

add back in guard against things like: '10 inches to 5 cm'

=item *

support native perl numbers in queries: e.g.: '12.34e-56 cm to mm'
support for various number formats (e.g., international)?
bignum support?

=item *

don't show decimals when integer answer? e.g.: '12.000' should be '12' (this may be something we leave to implementation ... see 'precision' argument)

=item *

what happens when two units have the same notation? (e.g., 'kilometer' and 'kilobyte' both can use 'K')

=item *

L<https://github.com/duckduckgo/zeroclickinfo-goodies/issues/1767>
return undef when we find a unit/alias in more than one type
^ what if it's ok? e.g., "oz" can be a unit of both "mass" and "volume"

=item *

perl critic?

=item *

Convert to p6

=item *

while massaging output is left to the implementation, there are some cases
where answers might seem nonsensical, based on the input precision.  
for example, converting '10mg to tons' with a precision of '3' gives '10 milligrams is 0.000 tons'
the code below is one way to handle such cases:

       if ($result == 0 || length($result) > 2*$precision + 1) {
           # '10 mg to tons'                 => [0] , [1.10231e-08]
           # '10000 minutes in microseconds' => [600000000000]
           # '2500kcal in tons of tnt'       => [66194.888]

           if ($result == 0) {
               # rounding error
               $result = convert_temperatures($matches->{'from_unit'}, $matches->{'to_unit'}, $factor);
           }

           $f_result = (sprintf "%.${precision}g", $result);
       }

=back

=cut
