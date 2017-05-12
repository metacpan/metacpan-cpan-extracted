use strict;
use warnings;
use utf8;

use File::Basename qw(basename);
use File::Spec;
use Test::More;

use DateTimeX::Lite::Locale;

my @locale_ids   = map {
    my $f = basename($_);
    $f =~ s/\.dat$//;
    $f
} grep {
    !/Aliases\.dat$/;
} sort <share/DateTimeX/Lite/Locale/*.dat>;
# my %locale_names = map { $_ => 1 } 
my %locale_ids   = map { $_ => 1 } @locale_ids;

eval { require DateTimeX::Lite };
my $has_dt = $@ ? 0 : 1;

my $dt = DateTimeX::Lite->new( year => 2000, month => 1, day => 1, time_zone => 'UTC' )
    if $has_dt;

my $tests_per_locale = $has_dt ? 25 : 21;

plan tests =>
    5    # starting
#    + 1  # load test for root locale
    + ( (@locale_ids - 1) * $tests_per_locale ) # test each local
    + 49 # check_root
    + 24 # check_en
    + 61 # check_en_GB
    + 23 # check_en_US
    + 11 # check_es_ES
    + 2  # check_af
    + 5  # check_en_US_POSIX
#    + 9  # check_DT_Lang
    ;

{
    ok( @locale_ids >= 240,     'Coverage looks complete' );
    note( "Available locales: ", explain(\@locale_ids) );
#    ok( $locale_names{English}, "Locale name 'English' found" );
    ok( $locale_ids{ar_JO},     "Locale id 'ar_JO' found" );

    eval { DateTimeX::Lite::Locale->load('Does not exist') };
    like( $@, qr/does not exist|invalid/i, 'invalid locale name/id to load() causes an error' );

    # this type of locale id should work
    my $l = DateTimeX::Lite::Locale->load('en_US.LATIN-1');
    is( $l->id, 'en_US', 'id is en_US' );
}

# testing the basics for all ids
{
    for my $locale_id (@locale_ids)
    {
        my $locale = eval { DateTimeX::Lite::Locale->load($locale_id) };

        isa_ok( $locale, 'DateTimeX::Lite::Locale' );

        next if $locale_id eq 'root';

        ok( $locale_ids{ $locale->id() }, "'$locale_id':  Has a valid locale id" );

        ok( length $locale->name(), "'$locale_id':  Has a locale name" );
        ok( length $locale->native_name(),
            "'$locale_id':  Has a native locale name" );

        # Each iteration runs one test if DateTime.pm is not available or
        # there is no matching DateTime.pm method, otherwise it runs two.
        for my $test ( { locale_method    => 'month_format_wide',
                         datetime_method  => 'month_name',
                         datetime_set_key => 'month',
                         count            => 12,
                       },
                       { locale_method    => 'month_format_abbreviated',
                         datetime_method  => 'month_abbreviation',
                         datetime_set_key => 'month',
                         count            => 12,
                       },
                       { locale_method    => 'day_format_wide',
                         datetime_method  => 'day_name',
                         datetime_set_key => 'day',
                         count            => 7,
                       },
                       { locale_method    => 'day_format_abbreviated',
                         datetime_method  => 'day_abbreviation',
                         datetime_set_key => 'day',
                         count            => 7,
                       },
                       { locale_method    => 'quarter_format_wide',
                         count            => 4,
                       },
                       { locale_method    => 'quarter_format_abbreviated',
                         count            => 4,
                       },
                       { locale_method    => 'am_pm_abbreviated',
                         count            => 2,
                       },
                       { locale_method    => 'era_wide',
                         count            => 2,
                       },
                       { locale_method    => 'era_abbreviated',
                         count            => 2,
                       },
                     )
        {
            check_array( locale => $locale, %$test );
        }

        # We can't actually expect these to be unique.
        is( scalar @{ $locale->day_format_narrow() }, 7, 'day_format_narrow() returns 7 items' );
        is( scalar @{ $locale->month_format_narrow() }, 12, 'month_format_narrow() returns 12 items' );
        is( scalar @{ $locale->day_stand_alone_narrow() }, 7, 'day_stand_alone_narrow() returns 7 items' );
        is( scalar @{ $locale->month_stand_alone_narrow() }, 12, 'month_stand_alone_narrow() returns 12 items' );

        check_formats( $locale_id, $locale, 'date_formats', 'date_format' );
        check_formats( $locale_id, $locale, 'time_formats', 'time_format' );
    }
}

check_root();
check_en();
check_en_GB();
check_en_US();
check_es_ES();
check_en_US_POSIX();
check_af();

sub check_array
{
    my %test = @_;

    my $locale_method = $test{locale_method};

    my %unique = map { $_ => 1 } @{ $test{locale}->$locale_method() };

    my $locale_id = $test{locale}->id();

 TODO:
    {
        local $TODO = 'The ii locale does not have unique abbreviated days for some reason'
            if $test{locale}->id() =~ /^ii/ && $locale_method eq 'day_format_abbreviated';

        is( keys %unique, $test{count},
            qq{'$locale_id': '$locale_method' contains $test{count} unique items} );
    }

    my $datetime_method = $test{datetime_method};
    return unless $datetime_method && $has_dt;

    for my $i ( 1..$test{count} )
    {
        $dt->set( $test{datetime_set_key} => $i );

        delete $unique{ $test{locale}->$datetime_method($dt) };
    }

    is( keys %unique, 0,
        "'$locale_id':  Data returned by '$locale_method' and '$datetime_method' matches" );
}

sub check_formats
{
    my ( $locale_id, $locale, $hash_func, $item_func ) = @_;

    my %unique = map { $_ => 1 } values %{ $locale->$hash_func() };

    ok( keys %unique >= 1, "'$locale_id': '$hash_func' contains at least 1 unique item" );

    foreach my $length ( qw( full long medium short ) )
    {
        my $method = $item_func . q{_} . $length;

        my $val = $locale->$method();

        if ( defined $val )
        {
            delete $unique{$val};
        }
        else
        {
            Test::More::diag( "$locale_id returned undef for $method()" );
        }
    }

    is( keys %unique, 0,
        "'$locale_id':  Data returned by '$hash_func' and '$item_func patterns' matches" );
}

sub check_root
{
    my $locale = DateTimeX::Lite::Locale->load('root');

    my %tests =
        ( day_format_wide =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          day_format_abbreviated =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          day_format_narrow =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          day_stand_alone_wide =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          day_stand_alone_abbreviated =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          day_stand_alone_narrow =>
          [ qw( 2 3 4 5 6 7 1 ) ],

          month_format_wide =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          month_format_abbreviated =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          month_format_narrow =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          month_stand_alone_wide =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          month_stand_alone_abbreviated =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          month_stand_alone_narrow =>
          [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 ) ],

          quarter_format_wide =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_format_abbreviated =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_format_narrow =>
          [ qw( 1 2 3 4 ) ],

          quarter_stand_alone_wide =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_stand_alone_abbreviated =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_stand_alone_narrow =>
          [ qw( 1 2 3 4 ) ],

          era_wide =>
          [ qw( BCE CE ) ],

          era_abbreviated =>
          [ qw( BCE CE ) ],

          era_narrow =>
          [ qw( BCE CE ) ],

          am_pm_abbreviated =>
          [ qw( AM PM ) ],

          datetime_format_full    => 'EEEE, yyyy MMMM dd HH:mm:ss v',
          datetime_format_long    => 'yyyy MMMM d HH:mm:ss z',
          datetime_format_medium  => 'yyyy MMM d HH:mm:ss',
          datetime_format_short   => 'yyyy-MM-dd HH:mm',

          datetime_format_default => 'yyyy MMM d HH:mm:ss',

          first_day_of_week => 1,

          prefers_24_hour_time    => 1,
        );

    test_data( $locale, %tests );

    my %formats =
        ( 'Hm'     => 'H:mm',
          'M'      => 'L',
          'MEd'    => 'E, M-d',
          'MMM'    => 'LLL',
          'MMMEd'  => 'E MMM d',
          'MMMMEd' => 'E MMMM d',
          'MMMMd'  => 'MMMM d',
          'MMMd'   => 'MMM d',
          'Md'     => 'M-d',
          'd'      => 'd',
          'ms'     => 'mm:ss',
          'y'      => 'yyyy',
          'yM'     => 'yyyy-M',
          'yMEd'   => 'EEE, yyyy-M-d',
          'yMMM'   => 'yyyy MMM',
          'yMMMEd' => 'EEE, yyyy MMM d',
          'yMMMM'  => 'yyyy MMMM',
          'yQ'     => 'yyyy Q',
          'yQQQ'   => 'yyyy QQQ',
        );

    test_formats( $locale, %formats );
}

sub check_en
{
    my $locale = DateTimeX::Lite::Locale->load('en');

    my %tests =
        ( en_data(),

          name => 'English',
        );

    test_data( $locale, %tests );
}

sub check_en_GB
{
    my $locale = DateTimeX::Lite::Locale->load('en_GB');

    my %tests =
        ( en_data(),

          first_day_of_week => 7,

          name             => 'English United Kingdom',
          native_name      => 'English United Kingdom',
          language         => 'English',
          native_language  => 'English',
          territory        => 'United Kingdom',
          native_territory => 'United Kingdom',
          variant          => undef,
          native_variant   => undef,

          language_id      => 'en',
          territory_id     => 'GB',
          variant_id       => undef,

          datetime_format_default => 'd MMM yyyy HH:mm:ss',
        );

    test_data( $locale, %tests );

    my %formats =
        ( # from en_GB
          'MEd' => 'E, d/M',
          'MMMEd' => 'E d MMM',
          'MMMMd' => 'd MMMM',
          'MMdd' => 'dd/MM',
          'Md' => 'd/M',
          'yMEd' => 'EEE, d/M/yyyy',
          'yyMMM' => 'MMM yy',
          'yyyyMM' => 'MM/yyyy',
          'yyyyMMMM' => 'MMMM yyyy',

          # from en
          'Hm' => 'HH:mm',
          'Hms' => 'HH:mm:ss',
          'M' => 'L',
          'MMM' => 'LLL',
          'MMMMEd' => 'E, MMMM d',
          'MMMd' => 'MMM d',
          'd' => 'd',
          'hm' => 'h:mm a',
          'ms' => 'mm:ss',
          'y' => 'yyyy',
          'yM' => 'M/yyyy',
          'yMMM' => 'MMM yyyy',
          'yMMMEd' => 'EEE, MMM d, yyyy',
          'yMMMM' => 'MMMM yyyy',
          'yQ' => 'Q yyyy',
          'yQQQ' => 'QQQ yyyy',
        );

    test_formats( $locale, %formats );
}

sub check_en_US
{
    my $locale = DateTimeX::Lite::Locale->load('en_US');

    my %tests =
        ( en_data(),

          first_day_of_week => 7,
        );

    test_data( $locale, %tests );
}

sub en_data
{
    return
        ( day_format_wide =>
          [ qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday ) ],

          day_format_abbreviated =>
          [ qw( Mon Tue Wed Thu Fri Sat Sun ) ],

          day_format_narrow =>
          [ qw( M T W T F S S ) ],

          day_stand_alone_wide =>
          [ qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday ) ],

          day_stand_alone_abbreviated =>
          [ qw( Mon Tue Wed Thu Fri Sat Sun ) ],

          day_stand_alone_narrow =>
          [ qw( M T W T F S S ) ],

          month_format_wide =>
          [ qw( January February March April May June
                July August September October November December ) ],

          month_format_abbreviated =>
          [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ) ],

          month_format_narrow =>
          [ qw( J F M A M J J A S O N D ) ],

          month_stand_alone_wide =>
          [ qw( January February March April May June
                July August September October November December ) ],

          month_stand_alone_abbreviated =>
          [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ) ],

          month_stand_alone_narrow =>
          [ qw( J F M A M J J A S O N D ) ],

          quarter_format_wide =>
          [ '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' ],

          quarter_format_abbreviated =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_format_narrow =>
          [ qw( 1 2 3 4 ) ],

          quarter_stand_alone_wide =>
          [ '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' ],

          quarter_stand_alone_abbreviated =>
          [ qw( Q1 Q2 Q3 Q4 ) ],

          quarter_stand_alone_narrow =>
          [ qw( 1 2 3 4 ) ],

          era_wide =>
          [ 'Before Christ', 'Anno Domini' ],

          era_abbreviated =>
          [ qw( BC AD ) ],

          era_narrow =>
          [ qw( B A ) ],

          am_pm_abbreviated =>
          [ qw( AM PM ) ],

          first_day_of_week => 1,
        );
}

sub test_data
{
    my $locale = shift;
    my %tests = @_;

    for my $k ( sort keys %tests )
    {
        TODO: {
        my $desc = "$k for " . $locale->id();

        if ($k eq 'name' || $k eq 'language') {
            todo_skip("$k unimplemented", 1);
        }

        if ( ref $tests{$k} )
        {
            is_deeply( $locale->$k(), $tests{$k}, $desc );
        }
        else
        {
            is( $locale->$k(), $tests{$k}, $desc );
        }
        }
    }
}

sub test_formats
{
    my $locale  = shift;
    my %formats = @_;

    for my $name ( keys %formats )
    {
        is( $locale->format_for($name), $formats{$name},
            "Format for $name with " . $locale->id() ) or
note( "got -> " . $locale->format_for($name) . ", expected: $formats{$name}");
    }

    TODO: {
        todo_skip("unimplemented", 1);
        is_deeply( [ $locale->available_formats() ],
                   [ sort keys %formats ],
                   "Available formats for " . $locale->id() . " match what is expected" );
    }
}

sub check_es_ES
{
    my $locale = DateTimeX::Lite::Locale->load('es_ES');

    is( $locale->name(), 'Spanish Spain', 'name()' );
    is( $locale->native_name(), 'español España', 'native_name()' );
    is( $locale->language(), 'Spanish', 'language()' );
    is( $locale->native_language(), 'español', 'native_language()' );
    is( $locale->territory(), 'Spain', 'territory()' );
    is( $locale->native_territory(), 'España', 'native_territory()' );
    is( $locale->variant(), undef, 'variant()' );
    is( $locale->native_variant(), undef, 'native_variant()' );

    is( $locale->language_id(), 'es', 'language_id()' );
    is( $locale->territory_id(), 'ES', 'territory_id()' );
    is( $locale->variant_id(), undef, 'variant_id()' );
}

sub check_af
{
    my $locale = DateTimeX::Lite::Locale->load('af');

    is_deeply( $locale->month_format_abbreviated(),
               [ qw( Jan Feb Mar Apr Mei Jun Jul Aug Sep Okt Nov Des ) ],
               'month abbreviations for af use non-draft form' );

    is_deeply( $locale->month_format_narrow(),
               [ 1..12 ],
               'month narrows for af use draft form because that is the only form available' );
}

sub check_en_US_POSIX
{
    my $locale = DateTimeX::Lite::Locale->load('en_US_POSIX');

    is( $locale->variant(), 'Computer', 'variant()' );
    is( $locale->native_variant(), 'Computer', 'native_variant()' );

    is( $locale->language_id(), 'en', 'language_id()' );
    is( $locale->territory_id(), 'US', 'territory_id()' );
    is( $locale->variant_id(), 'POSIX', 'variant_id()' );
}


