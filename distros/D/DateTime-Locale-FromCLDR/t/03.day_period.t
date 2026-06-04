#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $dt_class );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    elsif( $^O eq 'openbsd' && ( $^V >= v5.12.0 && $^V <= v5.12.5 ) )
    {
        plan skip_all => 'Weird memory bug out of my control on OpenBSD for v5.12.0 to 5';
    }

    # NOTE: We support both DateTime::Lite (preferred for speed) and DateTime.
    # If neither is installed, the tests are skipped. This avoids a circular dependency
    # between DateTime::Locale::FromCLDR and DateTime::Lite.
    if( eval{ require DateTime::Lite; 1 } )
    {
        $dt_class = 'DateTime::Lite';
    }
    elsif( eval{ require DateTime; 1 } )
    {
        $dt_class = 'DateTime';
    }
    else
    {
        plan skip_all => 'Neither DateTime::Lite nor DateTime is installed; cannot run day period tests';
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Locale::FromCLDR' ) || BAIL_OUT( 'Unable to load DateTime::Locale::FromCLDR' );
};

use strict;
use warnings;
use utf8;


my $tests = [
    {
        locale => 'en',
        terms =>
        [
            # midnight
            $dt_class->new(
                year => 2024,
                hour => 0
            ) => 'midnight',
            # morning1
            $dt_class->new(
                year => 2024,
                hour => 7
            ) => 'in the morning',
            # noon
            $dt_class->new(
                year => 2024,
                hour => 12
            ) => 'noon',
            # afternoon1
            $dt_class->new(
                year => 2024,
                hour => 13
            ) => 'in the afternoon',
            # evening1
            $dt_class->new(
                year => 2024,
                hour => 19
            ) => 'in the evening',
            # night1
            $dt_class->new(
                year => 2024,
                hour => 22
            ) => 'at night',
        ],
    },
    {
        locale => 'ja-Kana-JP',
        terms =>
        [
            # midnight
            $dt_class->new(
                year => 2024,
                hour => 0
            ) => '真夜中',
            # morning1
            $dt_class->new(
                year => 2024,
                hour => 7
            ) => '朝',
            # noon
            $dt_class->new(
                year => 2024,
                hour => 12
            ) => '正午',
            # afternoon1
            $dt_class->new(
                year => 2024,
                hour => 13
            ) => '昼',
            # evening1
            $dt_class->new(
                year => 2024,
                hour => 18
            ) => '夕方',
            # night1
            $dt_class->new(
                year => 2024,
                hour => 20
            ) => '夜',
            # night2
            $dt_class->new(
                year => 2024,
                hour => 23
            ) => '夜中',
        ],
    },
    {
        locale => 'fr',
        terms =>
        [
            # midnight
            $dt_class->new(
                year => 2024,
                hour => 0
            ) => 'minuit',
            # morning1
            $dt_class->new(
                year => 2024,
                hour => 7
            ) => 'matin',
            # noon
            $dt_class->new(
                year => 2024,
                hour => 12
            ) => 'midi',
            # afternoon1
            $dt_class->new(
                year => 2024,
                hour => 13
            ) => 'après-midi',
            # evening1
            $dt_class->new(
                year => 2024,
                hour => 18
            ) => 'soir',
            # evening1
            $dt_class->new(
                year => 2024,
                hour => 20
            ) => 'soir',
            # night1
            $dt_class->new(
                year => 2024,
                hour => 3
            ) => 'matin',
        ],
    },
];

my $year = $dt_class->now->year;
my( $dt1, $dt2, $diff );

foreach my $def ( @$tests )
{
    subtest $def->{locale} => sub
    {
        my $locale = DateTime::Locale::FromCLDR->new( $def->{locale} );
        SKIP:
        {
            if( !defined( $locale ) )
            {
                diag( "Error instantiating a DateTime::Locale::FromCLDR object for locale '$def->{locale}': ", DateTime::Locale::FromCLDR->error );
                fail( DateTime::Locale::FromCLDR->error );
                skip( "Unable to instantiate a DateTime::Locale::FromCLDR object for locale '$def->{locale}'", 1 );
            }
            isa_ok( $locale, 'DateTime::Locale::FromCLDR' );
            for( my $i = 0; $i < scalar( @{$def->{terms}} ); $i += 2 )
            {
                my $dt = $def->{terms}->[$i];
                my $expect = $def->{terms}->[$i+1];
                my $str = $locale->day_period_format_abbreviated( $dt );
                is( $str, $expect, 'day_period for ' . $dt->iso8601 . ' -> ' . $expect );
            }
        };
    };
}

done_testing();

# NOTE: OpenBSD global destruction workaround
# On OpenBSD, a double free deep in the SQLite-backed dependency stack corrupts the heap during
# perl's global destruction. The OpenBSD allocator is strict and aborts the process on exit, which
# the harness then misreads as a failure even though every assertion above has already passed.
# Once done_testing() has emitted the TAP stream, we flush the standard handles and hard-exit,
# bypassing global destruction entirely. This is restricted to OpenBSD so that normal teardown,
# and the diagnostics it can surface, are preserved on every other platform.
if( $^O eq 'openbsd' )
{
    my $builder = Test::More->builder;
    my $passing = $builder->can( 'is_passing' ) ? $builder->is_passing : 1;
    require IO::Handle;
    STDOUT->flush;
    STDERR->flush;
    require POSIX;
    POSIX::_exit( $passing ? 0 : 1 );
}

__END__
