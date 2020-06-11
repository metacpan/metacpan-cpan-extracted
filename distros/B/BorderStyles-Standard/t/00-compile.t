use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 30 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'BorderStyle/ASCII/None.pm',
    'BorderStyle/ASCII/SingleLine.pm',
    'BorderStyle/ASCII/SingleLineHorizontalOnly.pm',
    'BorderStyle/ASCII/SingleLineInnerOnly.pm',
    'BorderStyle/ASCII/SingleLineOuterOnly.pm',
    'BorderStyle/ASCII/SingleLineVerticalOnly.pm',
    'BorderStyle/ASCII/Space.pm',
    'BorderStyle/ASCII/SpaceInnerOnly.pm',
    'BorderStyle/BoxChar/None.pm',
    'BorderStyle/BoxChar/SingleLine.pm',
    'BorderStyle/BoxChar/SingleLineHorizontalOnly.pm',
    'BorderStyle/BoxChar/SingleLineInnerOnly.pm',
    'BorderStyle/BoxChar/SingleLineOuterOnly.pm',
    'BorderStyle/BoxChar/SingleLineVerticalOnly.pm',
    'BorderStyle/BoxChar/Space.pm',
    'BorderStyle/BoxChar/SpaceInnerOnly.pm',
    'BorderStyle/UTF8/Brick.pm',
    'BorderStyle/UTF8/BrickOuterOnly.pm',
    'BorderStyle/UTF8/DoubleLine.pm',
    'BorderStyle/UTF8/None.pm',
    'BorderStyle/UTF8/SingleLine.pm',
    'BorderStyle/UTF8/SingleLineBold.pm',
    'BorderStyle/UTF8/SingleLineCurved.pm',
    'BorderStyle/UTF8/SingleLineHorizontalOnly.pm',
    'BorderStyle/UTF8/SingleLineInnerOnly.pm',
    'BorderStyle/UTF8/SingleLineOuterOnly.pm',
    'BorderStyle/UTF8/SingleLineVerticalOnly.pm',
    'BorderStyle/UTF8/Space.pm',
    'BorderStyle/UTF8/SpaceInnerOnly.pm',
    'BorderStyles/Standard.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


