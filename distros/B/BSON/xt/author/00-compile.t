use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 26;

my @module_files = (
    'BSON.pm',
    'BSON/Array.pm',
    'BSON/Binary.pm',
    'BSON/Bool.pm',
    'BSON/Bytes.pm',
    'BSON/Code.pm',
    'BSON/DBPointer.pm',
    'BSON/DBRef.pm',
    'BSON/Decimal128.pm',
    'BSON/Doc.pm',
    'BSON/Double.pm',
    'BSON/Int32.pm',
    'BSON/Int64.pm',
    'BSON/MaxKey.pm',
    'BSON/MinKey.pm',
    'BSON/OID.pm',
    'BSON/ObjectId.pm',
    'BSON/PP.pm',
    'BSON/Raw.pm',
    'BSON/Regex.pm',
    'BSON/String.pm',
    'BSON/Symbol.pm',
    'BSON/Time.pm',
    'BSON/Timestamp.pm',
    'BSON/Types.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


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


