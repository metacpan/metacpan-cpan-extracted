use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 19 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Bencher/Scenario/PERLANCAR/CommonModulesStartup.pm',
    'Bencher/Scenario/PERLANCAR/In.pm',
    'Bencher/Scenario/PERLANCAR/PERLANCARwarningsStartup.pm',
    'Bencher/Scenario/PERLANCAR/grep_bool.pm',
    'Bencher/Scenario/PERLANCAR/method_call_using_variable.pm',
    'Bencher/Scenario/PERLANCAR/pass_list_vs_array.pm',
    'Bencher/Scenario/PERLANCAR/pkg_to_pkgpm.pm',
    'Bencher/Scenario/PERLANCAR/require.pm',
    'Bencher/Scenario/PERLANCAR/state.pm',
    'Bencher/ScenarioR/PERLANCAR/CommonModulesStartup.pm',
    'Bencher/ScenarioR/PERLANCAR/In.pm',
    'Bencher/ScenarioR/PERLANCAR/PERLANCARwarningsStartup.pm',
    'Bencher/ScenarioR/PERLANCAR/grep_bool.pm',
    'Bencher/ScenarioR/PERLANCAR/method_call_using_variable.pm',
    'Bencher/ScenarioR/PERLANCAR/pass_list_vs_array.pm',
    'Bencher/ScenarioR/PERLANCAR/pkg_to_pkgpm.pm',
    'Bencher/ScenarioR/PERLANCAR/require.pm',
    'Bencher/ScenarioR/PERLANCAR/state.pm',
    'Bencher/Scenarios/PERLANCAR.pm'
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


