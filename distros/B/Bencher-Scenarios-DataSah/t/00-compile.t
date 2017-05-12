use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 15 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Bencher/Scenario/DataSah/Coerce.pm',
    'Bencher/Scenario/DataSah/Startup.pm',
    'Bencher/Scenario/DataSah/Validate.pm',
    'Bencher/Scenario/DataSah/extract_subschemas.pm',
    'Bencher/Scenario/DataSah/gen_coercer.pm',
    'Bencher/Scenario/DataSah/gen_validator.pm',
    'Bencher/Scenario/DataSah/normalize_schema.pm',
    'Bencher/ScenarioR/DataSah/Coerce.pm',
    'Bencher/ScenarioR/DataSah/Startup.pm',
    'Bencher/ScenarioR/DataSah/Validate.pm',
    'Bencher/ScenarioR/DataSah/extract_subschemas.pm',
    'Bencher/ScenarioR/DataSah/gen_coercer.pm',
    'Bencher/ScenarioR/DataSah/gen_validator.pm',
    'Bencher/ScenarioR/DataSah/normalize_schema.pm',
    'Bencher/Scenarios/DataSah.pm'
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


