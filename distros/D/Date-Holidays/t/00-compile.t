use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 22;

my @module_files = (
    'Date/Holidays.pm',
    'Date/Holidays/Adapter.pm',
    'Date/Holidays/Adapter/AU.pm',
    'Date/Holidays/Adapter/BR.pm',
    'Date/Holidays/Adapter/BY.pm',
    'Date/Holidays/Adapter/CN.pm',
    'Date/Holidays/Adapter/DE.pm',
    'Date/Holidays/Adapter/DK.pm',
    'Date/Holidays/Adapter/ES.pm',
    'Date/Holidays/Adapter/FR.pm',
    'Date/Holidays/Adapter/GB.pm',
    'Date/Holidays/Adapter/JP.pm',
    'Date/Holidays/Adapter/KR.pm',
    'Date/Holidays/Adapter/KZ.pm',
    'Date/Holidays/Adapter/Local.pm',
    'Date/Holidays/Adapter/NO.pm',
    'Date/Holidays/Adapter/NZ.pm',
    'Date/Holidays/Adapter/PL.pm',
    'Date/Holidays/Adapter/PT.pm',
    'Date/Holidays/Adapter/RU.pm',
    'Date/Holidays/Adapter/SK.pm',
    'Date/Holidays/Adapter/USFederal.pm'
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



# no warning checks;


