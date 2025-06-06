use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 21;

my @module_files = (
    'Data/Transfigure.pm',
    'Data/Transfigure/Constants.pm',
    'Data/Transfigure/Default.pm',
    'Data/Transfigure/Default/ToString.pm',
    'Data/Transfigure/HashFilter/Undef.pm',
    'Data/Transfigure/HashKeys/CamelCase.pm',
    'Data/Transfigure/HashKeys/CapitalizedIDSuffix.pm',
    'Data/Transfigure/HashKeys/SnakeCase.pm',
    'Data/Transfigure/Node.pm',
    'Data/Transfigure/Position.pm',
    'Data/Transfigure/Predicate.pm',
    'Data/Transfigure/Schema.pm',
    'Data/Transfigure/Tree.pm',
    'Data/Transfigure/Tree/Merge.pm',
    'Data/Transfigure/Type.pm',
    'Data/Transfigure/Type/DBIx.pm',
    'Data/Transfigure/Type/DBIx/Recursive.pm',
    'Data/Transfigure/Type/DateTime.pm',
    'Data/Transfigure/Type/DateTime/Duration.pm',
    'Data/Transfigure/Value.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


