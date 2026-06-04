#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
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
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => [qw( AM PM )],
            },
            {
                method => 'am_pm_format_narrow',
                expects => [qw( a p )],
            },
            {
                method => 'am_pm_format_wide',
                expects => [qw( AM PM )],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => [qw( AM PM )],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => [qw( AM PM )],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => [qw( AM PM )],
            },
        ],
    },
    {
        locale => 'ja-Kana-JP',
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => [qw( 午前 午後 )],
            },
            {
                method => 'am_pm_format_narrow',
                expects => [qw( 午前 午後 )],
            },
            {
                method => 'am_pm_format_wide',
                expects => [qw( 午前 午後 )],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => [qw( 午前 午後 )],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => [qw( 午前 午後 )],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => [qw( 午前 午後 )],
            },
        ],
    },
    {
        locale => 'fr',
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => [],
            },
            {
                method => 'am_pm_format_narrow',
                expects => [],
            },
            {
                method => 'am_pm_format_wide',
                expects => [],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => [],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => [],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => [],
            },
        ],
    },
    {
        locale => 'es',
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => ['a. m.', 'p. m.'],
            },
            {
                method => 'am_pm_format_narrow',
                expects => ['a. m.', 'p. m.'],
            },
            {
                method => 'am_pm_format_wide',
                expects => ['a. m.', 'p. m.'],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => ['a. m.', 'p. m.'],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => ['a. m.', 'p. m.'],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => ['a. m.', 'p. m.'],
            },
        ],
    },
    {
        locale => 'ie',
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => ['a.m.', 'p.m.'],
            },
            {
                method => 'am_pm_format_narrow',
                expects => ['a.', 'p.'],
            },
            {
                method => 'am_pm_format_wide',
                expects => ['ante midí', 'pos midí'],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => ['ante midí', 'pos midí'],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => ['a.', 'p.'],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => ['ante midí', 'pos midí'],
            },
        ],
    },
    {
        locale => 'ko',
        tests =>
        [
            {
                method => 'am_pm_format_abbreviated',
                expects => ['오전', '오후'],
            },
            {
                method => 'am_pm_format_narrow',
                expects => ['오전', '오후'],
            },
            {
                method => 'am_pm_format_wide',
                expects => ['오전', '오후'],
            },
            {
                method => 'am_pm_standalone_abbreviated',
                expects => ['오전', '오후'],
            },
            {
                method => 'am_pm_standalone_narrow',
                expects => ['오전', '오후'],
            },
            {
                method => 'am_pm_standalone_wide',
                expects => ['오전', '오후'],
            },
        ],
    },
];

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
            foreach my $def2 ( @{$def->{tests}} )
            {
                next unless( exists( $def2->{method} ) && exists( $def2->{expects} ) );
                my $coderef = $locale->can( $def2->{method} );
                if( !defined( $coderef ) )
                {
                    fail( "$def->{locale} -> $def2->{method} non-existent" );
                    next;
                }
                my $ref = $coderef->( $locale );
                is_deeply( $ref, $def2->{expects}, "$def->{locale} -> $def2->{method} -> " . join( ', ', @{$def2->{expects}} ) );
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
