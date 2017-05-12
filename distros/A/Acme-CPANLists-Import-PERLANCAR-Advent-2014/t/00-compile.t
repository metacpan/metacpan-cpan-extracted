use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 25 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_01.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_02.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_03.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_04.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_05.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_06.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_07.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_08.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_09.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_10.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_11.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_12.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_13.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_14.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_15.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_16.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_17.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_18.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_19.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_20.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_21.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_22.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_23.pm',
    'Acme/CPANLists/Import/PERLANCAR/Advent/2014_12_24.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


