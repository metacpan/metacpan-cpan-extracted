use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 20 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Acme/CPANLists/PERLANCAR.pm',
    'Acme/CPANLists/PERLANCAR/ArrayClassBuilder.pm',
    'Acme/CPANLists/PERLANCAR/Assert.pm',
    'Acme/CPANLists/PERLANCAR/Avoided.pm',
    'Acme/CPANLists/PERLANCAR/CLIWithUndo.pm',
    'Acme/CPANLists/PERLANCAR/CustomCPAN.pm',
    'Acme/CPANLists/PERLANCAR/LocalCPANMirror.pm',
    'Acme/CPANLists/PERLANCAR/MagicVariableTechnique.pm',
    'Acme/CPANLists/PERLANCAR/MooseStyleClassBuilder.pm',
    'Acme/CPANLists/PERLANCAR/MyGetoptLongExperiment.pm',
    'Acme/CPANLists/PERLANCAR/NonMooseStyleClassBuilder.pm',
    'Acme/CPANLists/PERLANCAR/OneLetter.pm',
    'Acme/CPANLists/PERLANCAR/Retired.pm',
    'Acme/CPANLists/PERLANCAR/Task/CheckingModuleInstalledLoadable.pm',
    'Acme/CPANLists/PERLANCAR/Task/GettingTempDir.pm',
    'Acme/CPANLists/PERLANCAR/Task/PickingRandomLinesFromFile.pm',
    'Acme/CPANLists/PERLANCAR/Task/WorkingWithTree.pm',
    'Acme/CPANLists/PERLANCAR/Unbless.pm',
    'Acme/CPANLists/PERLANCAR/UpsideDownTextWithUnicode.pm',
    'Acme/CPANLists/PERLANCAR/Weird.pm'
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
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


