use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 31 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/JobLog.pm',
    'App/JobLog/Command.pm',
    'App/JobLog/Command/add.pm',
    'App/JobLog/Command/configure.pm',
    'App/JobLog/Command/done.pm',
    'App/JobLog/Command/edit.pm',
    'App/JobLog/Command/info.pm',
    'App/JobLog/Command/last.pm',
    'App/JobLog/Command/modify.pm',
    'App/JobLog/Command/note.pm',
    'App/JobLog/Command/parse.pm',
    'App/JobLog/Command/resume.pm',
    'App/JobLog/Command/summary.pm',
    'App/JobLog/Command/tags.pm',
    'App/JobLog/Command/today.pm',
    'App/JobLog/Command/truncate.pm',
    'App/JobLog/Command/vacation.pm',
    'App/JobLog/Command/when.pm',
    'App/JobLog/Config.pm',
    'App/JobLog/Log.pm',
    'App/JobLog/Log/Day.pm',
    'App/JobLog/Log/Event.pm',
    'App/JobLog/Log/Format.pm',
    'App/JobLog/Log/Line.pm',
    'App/JobLog/Log/Note.pm',
    'App/JobLog/Log/Synopsis.pm',
    'App/JobLog/Time.pm',
    'App/JobLog/TimeGrammar.pm',
    'App/JobLog/Vacation.pm',
    'App/JobLog/Vacation/Period.pm'
);

my @scripts = (
    'bin/job'
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


