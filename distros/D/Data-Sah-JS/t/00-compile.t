use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 21 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Compiler/js.pm',
    'Data/Sah/Compiler/js/TH.pm',
    'Data/Sah/Compiler/js/TH/all.pm',
    'Data/Sah/Compiler/js/TH/any.pm',
    'Data/Sah/Compiler/js/TH/array.pm',
    'Data/Sah/Compiler/js/TH/bool.pm',
    'Data/Sah/Compiler/js/TH/buf.pm',
    'Data/Sah/Compiler/js/TH/cistr.pm',
    'Data/Sah/Compiler/js/TH/code.pm',
    'Data/Sah/Compiler/js/TH/date.pm',
    'Data/Sah/Compiler/js/TH/duration.pm',
    'Data/Sah/Compiler/js/TH/float.pm',
    'Data/Sah/Compiler/js/TH/hash.pm',
    'Data/Sah/Compiler/js/TH/int.pm',
    'Data/Sah/Compiler/js/TH/num.pm',
    'Data/Sah/Compiler/js/TH/obj.pm',
    'Data/Sah/Compiler/js/TH/re.pm',
    'Data/Sah/Compiler/js/TH/str.pm',
    'Data/Sah/Compiler/js/TH/undef.pm',
    'Data/Sah/JS.pm',
    'Test/Data/Sah/JS.pm'
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


