## no critic (Modules::ProhibitExcessMainComplexity)
use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Fatal;

use Cwd qw( abs_path cwd );
use DateTime::TimeZone::Local;
use DateTime::TimeZone::Local::Unix;
use File::Basename qw( basename );
use File::Spec::Functions qw( catdir catfile curdir );
use File::Path qw( mkpath );
use File::Temp qw( tempdir );
use Sys::Hostname qw( hostname );
use Try::Tiny;

plan skip_all => 'HPUX is weird'
    if $^O eq 'hpux';

# Ensures that we can load our OS-specific subclass. Otherwise this
# might happen later in an eval, and the error will get lost.

## no critic (Subroutines::ProtectPrivateSubs)
DateTime::TimeZone::Local->_load_subclass() =~ /Unix$/
    or plan skip_all => 'These tests only run on Unix-ish OSes';

my $IsMaintainer = hostname() =~ /houseabsolute|quasar/ && -d '.hg';
my $CanWriteEtcLocaltime = -w '/etc/localtime' && -l '/etc/localtime';
my $CanSymlink = try {
## no critic (InputOutput::RequireCheckedSyscalls)
    symlink q{}, q{};
    1;
};
my ($TestFile) = abs_path($0) =~ /(.+)/;

local $ENV{TZ} = undef;

{
    my %links = DateTime::TimeZone->links();

    for my $alias ( sort keys %{ DateTime::TimeZone::links() } ) {
        local $ENV{TZ} = $alias;
        my $tz = try { DateTime::TimeZone::Local->TimeZone() };
        is(
            $tz->name(), $links{$alias},
            "$alias in \$ENV{TZ} for Local->TimeZone()"
        );
    }
}

{
    for my $name ( sort DateTime::TimeZone::all_names() ) {
        local $ENV{TZ} = $name;
        my $tz = try { DateTime::TimeZone::Local->TimeZone() };
        is(
            $tz->name(), $name,
            "$name in \$ENV{TZ} for Local->TimeZone()"
        );
    }
}

{
    local $ENV{TZ} = 'this will not work';

    my $tz = DateTime::TimeZone::Local::Unix->FromEnv();
    is(
        $tz, undef,
        'invalid time zone name in $ENV{TZ} fails'
    );

    local $ENV{TZ} = '123/456';

    $tz = DateTime::TimeZone::Local::Unix->FromEnv();
    is(
        $tz, undef,
        'invalid time zone name in $ENV{TZ} fails'
    );
}

{
    local $ENV{TZ} = 'Africa/Lagos';

    my $tz = DateTime::TimeZone::Local::Unix->FromEnv();
    is(
        $tz->name(), 'Africa/Lagos',
        'tz object name() is Africa::Lagos'
    );

    local $ENV{TZ} = 0;
    $tz = try { DateTime::TimeZone::Local->TimeZone() };
    is(
        $tz->name(), 'UTC',
        '$ENV{TZ} set to 0 returns UTC'
    );
}

{

    # This passes the _IsValidName() check but when passed to
    # DT::TZ->new() will throw an exception.
    {

        package Foo;
        use overload q{""} => sub {'Foo'}, 'eq' => sub { "$_[0]" eq "$_[1]" };
    }
    local $ENV{TZ} = bless [], 'Foo';

    DateTime::TimeZone::Local::Unix->FromEnv();
    is( $@, q{}, 'FromEnv does not leave $@ set' );
}

{
    local $^O = 'DoesNotExist';
    my @err;
    try {
        local $SIG{__DIE__} = sub { push @err, shift };
        DateTime::TimeZone::Local->_load_subclass();
    };

    is_deeply(
        \@err, [],
        'error loading local time zone module is not seen by __DIE__ handler'
    );
}

no warnings 'redefine';

SKIP:
{
    skip 'These tests require a file system that supports symlinks', 6
        unless $CanSymlink;

    my $etc_dir = tempdir( CLEANUP => 1 );
    ## no critic (Variables::ProhibitPackageVars)
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    # It doesn't matter what this links to since we override _ReadLink below.
    symlink $TestFile => catfile( $etc_dir, 'localtime' ) or die $!;

    ## no critic (Variables::ProtectPrivateVars)
    local *DateTime::TimeZone::Local::Unix::_Readlink
        = sub {'/usr/share/zoneinfo/US/Eastern'};

    my $tz;
    is(
        exception {
            $tz = DateTime::TimeZone::Local::Unix->FromEtcLocaltime()
        },
        undef,
        'valid time zone name in /etc/localtime symlink should not die'
    );
    is(
        $tz->name(), 'America/New_York',
        'FromEtchLocaltime() with _Readlink returning /usr/share/zoneinfo/US/Eastern'
    );

    local *DateTime::TimeZone::Local::Unix::_Readlink
        = sub {'/usr/share/zoneinfo/Foo/Bar'};

    $tz = DateTime::TimeZone::Local::Unix->FromEtcLocaltime();
    is(
        $@, q{},
        'valid time zone name in /etc/localtime symlink should not leave $@ set'
    );
    ok( !$tz, 'no time zone was found' );

    local *DateTime::TimeZone::Local::Unix::_Readlink = sub {undef};
    local *DateTime::TimeZone::Local::Unix::_FindMatchingZoneinfoFile
        = sub {'America/Los_Angeles'};

    is(
        exception {
            $tz = DateTime::TimeZone::Local::Unix->FromEtcLocaltime()
        },
        undef,
        'fall back to _FindMatchZoneinfoFile if _Readlink finds nothing'
    );
    is(
        $tz->name(), 'America/Los_Angeles',
        'FromEtchLocaltime() with _FindMatchingZoneinfoFile returning America/Los_Angeles'
    );
}

{
    ## no critic (Variables::ProhibitPackageVars, Variables::ProtectPrivateVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    mkpath( catdir( $etc_dir, 'sysconfig' ), 0, 0755 );
    open my $fh, '>', catfile( $etc_dir, 'sysconfig', 'clock' )
        or die $!;
    close $fh or die $!;

    local *DateTime::TimeZone::Local::Unix::_ReadEtcSysconfigClock
        = sub {'US/Eastern'};

    my $tz;
    is(
        exception {
            $tz = DateTime::TimeZone::Local::Unix->FromEtcSysconfigClock()
        },
        undef,
        'valid time zone name in /etc/sysconfig/clock should not die'
    );

    is(
        $tz->name(), 'America/New_York',
        'FromEtcSysConfigClock() with _ReadEtcSysconfigClock returning US/Eastern'
    );
}

{
    ## no critic (Variables::ProhibitPackageVars, Variables::ProtectPrivateVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    mkpath( catdir( $etc_dir, 'default' ), 0, 0755 );
    open my $fh, '>', catfile( $etc_dir, 'default', 'init' )
        or die $!;
    close $fh or die $!;

    local *DateTime::TimeZone::Local::Unix::_ReadEtcDefaultInit
        = sub {'Asia/Tokyo'};

    my $tz;
    is(
        exception {
            $tz = DateTime::TimeZone::Local::Unix->FromEtcDefaultInit()
        },
        undef,
        'valid time zone name in /etc/default/init should not die'
    );

    is(
        $tz->name(), 'Asia/Tokyo',
        'FromEtcDefaultInit with _ReadEtcDefaultInit returning Asia/Tokyo'
    );
}

{
    ## no critic (Variables::ProhibitPackageVars, Variables::ProtectPrivateVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    local $ENV{TZ} = q{};

SKIP:
    {
        skip 'These tests require a file system that supports symlinks', 2
            unless $CanSymlink;

        my $zoneinfo_dir = catdir( $etc_dir, qw( share zoneinfo ) );
        local $DateTime::TimeZone::Local::Unix::ZoneinfoDir = $zoneinfo_dir;

        mkpath( catdir( $zoneinfo_dir, 'America' ) );

        # The contents of this file are irrelevant but it cannot be zero size. All
        # that matters is the name.
        my $tz_file = catfile( $zoneinfo_dir, 'America', 'Chicago' );
        open my $fh, '>', $tz_file or die $!;
        print {$fh} 'foo' or die $!;
        close $fh or die $!;

        symlink $tz_file => catfile( $etc_dir, 'localtime' ) or die $!;

        my $tz;
        is(
            exception { $tz = DateTime::TimeZone::Local->TimeZone() },
            undef,
            'valid time zone name in /etc/localtime should not die'
        );
        is(
            $tz->name(), 'America/Chicago',
            '/etc/localtime should link to America/Chicago'
        );
    }

    {
        my $tz_file = catdir( $etc_dir, 'timezone' );
        open my $fh, '>', $tz_file or die $!;
        print {$fh} "America/Chicago\n" or die $!;
        close $fh or die $!;

        local *DateTime::TimeZone::Local::Unix::FromEtcLocaltime
            = sub {undef};

        my $tz;
        is(
            exception { $tz = DateTime::TimeZone::Local->TimeZone() },
            undef,
            'valid time zone name in /etc/timezone should not die'
        );
        is(
            $tz->name(), 'America/Chicago',
            '/etc/timezone should contain America/Chicago'
        );
    }
}

{
    ## no critic (Variables::ProhibitPackageVars, Variables::ProtectPrivateVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    my $default_dir = catdir( $etc_dir, 'default' );

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    mkpath( $default_dir, 0, 0755 );

    my $tz_file = catfile( $default_dir, 'init' );

    open my $fh, '>', $tz_file or die $!;
    print {$fh} "TZ=Australia/Melbourne\n" or die $!;
    close $fh or die $!;

    {
        # requires that /etc/default/init contain
        # TZ=Australia/Melbourne to work.
        local *DateTime::TimeZone::Local::Unix::FromEtcLocaltime
            = sub {undef};
        local *DateTime::TimeZone::Local::Unix::FromEtcTimezone = sub {undef};
        local *DateTime::TimeZone::Local::Unix::FromEtcTIMEZONE = sub {undef};

        my $tz;
        is(
            exception { $tz = DateTime::TimeZone::Local->TimeZone() },
            undef,
            '/etc/default/init contains TZ=Australia/Melbourne'
        );
        is(
            $tz->name(), 'Australia/Melbourne',
            '/etc/default/init should contain Australia/Melbourne'
        );
    }
}

{
    ## no critic (Variables::ProhibitPackageVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    my $tz_file = catfile( $etc_dir, 'timezone' );

    open my $fh, '>', $tz_file
        or die "Cannot write to $tz_file: $!";
    print {$fh} 'Foo/Bar' or die $!;
    close $fh or die $!;

    DateTime::TimeZone::Local::Unix->FromEtcTimezone();
    is(
        $@, q{},
        'calling FromEtcTimezone when it contains a bad name should not leave $@ set'
    );
}

{
    ## no critic (Variables::ProhibitPackageVars)

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    my $tz_file = catfile( $etc_dir, 'timezone' );

    open my $fh, '>', $tz_file
        or die "Cannot write to $tz_file: $!";
    print {$fh} "TZ = Foo/Bar\n" or die $!;
    close $fh or die $!;

    DateTime::TimeZone::Local::Unix->FromEtcTIMEZONE();
    is(
        $@, q{},
        'calling FromEtcTIMEZONE when it contains a bad name should not leave $@ set'
    );
}

SKIP:
{
    ## no critic (Variables::ProhibitPackageVars)

    my $zone_file = '/usr/share/zoneinfo/Asia/Kolkata';
    skip
        'These tests require an up to date IANA database under /usr/share/zoneinfo',
        5
        unless -f $zone_file && -s _;

    my $etc_dir = tempdir( CLEANUP => 1 );
    local $DateTime::TimeZone::Local::Unix::EtcDir = $etc_dir;

    require File::Copy;
    File::Copy::copy( $zone_file, catfile( $etc_dir, 'localtime' ) )
        or die
        "Cannot copy /usr/share/zoneinfo/Asia/Kolkata to '/etc/localtime': $!";

    {
        local $ENV{TZ} = q{};

        my $cwd = cwd();

        my $tz;
        is(
            exception { $tz = DateTime::TimeZone::Local->TimeZone() },
            undef,
            'copy of zoneinfo file at /etc/localtime'
        );
        is(
            $tz->name(), 'Asia/Kolkata',
            '/etc/localtime should be a copy of Asia/Kolkata'
        );

        is(
            cwd(), $cwd,
            'cwd should not change after finding local time zone'
        );

        $tz = DateTime::TimeZone::Local->TimeZone();
        is( $@, q{}, 'calling _FindMatchZoneinfoFile does not leave $@ set' );
    }

    {
        local $ENV{TZ} = q{};

        # Make sure that a die handler does not break our use of die
        # to escape from File::Find::find()
        local $SIG{__DIE__} = sub { die 'haha'; };

        my $tz;
        is(
            exception { $tz = DateTime::TimeZone::Local->TimeZone() },
            undef,
            'no exception from DateTime::Time::Local->TimeZone'
        );
        is(
            $tz->name(), 'Asia/Kolkata',
            'a __DIE__ handler did not interfere with our use of File::Find'
        );
    }
}

{
    local $ENV{TZ} = 'Australia/Melbourne';
    my $tz = try { DateTime::TimeZone->new( name => 'local' ) };
    is(
        $tz->name(), 'Australia/Melbourne',
        q|DT::TZ->new( name => 'local' )|
    );
}

SKIP:
{
    skip 'These tests require a filesystem which support symlinks', 1
        unless $CanSymlink;

    my $tempdir = tempdir( CLEANUP => 1 );

    my $first = File::Spec->catfile( $tempdir, 'first' );
    open my $fh, '>', $first
        or die "Cannot open $first: $!";
    close $fh or die $!;

    my $second = File::Spec->catfile( $tempdir, 'second' );
    symlink $first => $second
        or die "Cannot symlink $first => $second: $!";

    my $third = File::Spec->catfile( $tempdir, 'third' );
    symlink $second => $third
        or die "Cannot symlink $first => $second: $!";

    # It seems that on some systems (OSX, others?) the temp directory
    # returned by File::Temp may be a symlink (/tmp is a link to
    # /private/tmp), so when abs_path folows that link, we end up with
    # a different path to the "first" file.
    is(
        basename( DateTime::TimeZone::Local::Unix->_Readlink($third) ),
        basename($first),
        '_Readlink follows multiple levels of symlinking'
    );
}

done_testing();
