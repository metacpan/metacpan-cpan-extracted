use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 41 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/CompleteCLIs.pm'
);

my @scripts = (
    'bin/complete-array-elem',
    'bin/complete-dist',
    'bin/complete-dzil-bundle',
    'bin/complete-dzil-plugin',
    'bin/complete-dzil-role',
    'bin/complete-env',
    'bin/complete-env-elem',
    'bin/complete-file',
    'bin/complete-float',
    'bin/complete-gid',
    'bin/complete-group',
    'bin/complete-hash-key',
    'bin/complete-int',
    'bin/complete-kernel',
    'bin/complete-known-host',
    'bin/complete-known-mac',
    'bin/complete-locale',
    'bin/complete-manpage',
    'bin/complete-manpage-section',
    'bin/complete-module',
    'bin/complete-path-env-elem',
    'bin/complete-perl-builtin-function',
    'bin/complete-perl-builtin-symbol',
    'bin/complete-perl-version',
    'bin/complete-pid',
    'bin/complete-proc-name',
    'bin/complete-program',
    'bin/complete-regexp-pattern-module',
    'bin/complete-regexp-pattern-pattern',
    'bin/complete-riap-url',
    'bin/complete-riap-url-clientless',
    'bin/complete-service-name',
    'bin/complete-service-port',
    'bin/complete-tz',
    'bin/complete-uid',
    'bin/complete-user',
    'bin/complete-weaver-bundle',
    'bin/complete-weaver-plugin',
    'bin/complete-weaver-role',
    'bin/complete-weaver-section'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


