use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/PDRUtils.pm',
    'App/PDRUtils/Cmd.pm',
    'App/PDRUtils/DistIniCmd.pm',
    'App/PDRUtils/DistIniCmd/_modify_prereq_version.pm',
    'App/PDRUtils/DistIniCmd/add_prereq.pm',
    'App/PDRUtils/DistIniCmd/dec_prereq_version_by.pm',
    'App/PDRUtils/DistIniCmd/dec_prereq_version_to.pm',
    'App/PDRUtils/DistIniCmd/inc_prereq_version_by.pm',
    'App/PDRUtils/DistIniCmd/inc_prereq_version_to.pm',
    'App/PDRUtils/DistIniCmd/list_prereqs.pm',
    'App/PDRUtils/DistIniCmd/remove_prereq.pm',
    'App/PDRUtils/DistIniCmd/set_prereq_version_to.pm',
    'App/PDRUtils/DistIniCmd/sort_prereqs.pm',
    'App/PDRUtils/MultiCmd.pm',
    'App/PDRUtils/MultiCmd/add_prereq.pm',
    'App/PDRUtils/MultiCmd/dec_prereq_version_by.pm',
    'App/PDRUtils/MultiCmd/dec_prereq_version_to.pm',
    'App/PDRUtils/MultiCmd/inc_prereq_version_by.pm',
    'App/PDRUtils/MultiCmd/inc_prereq_version_to.pm',
    'App/PDRUtils/MultiCmd/ls.pm',
    'App/PDRUtils/MultiCmd/remove_prereq.pm',
    'App/PDRUtils/MultiCmd/set_prereq_version_to.pm',
    'App/PDRUtils/MultiCmd/sort_prereqs.pm',
    'App/PDRUtils/SingleCmd.pm',
    'App/PDRUtils/SingleCmd/add_prereq.pm',
    'App/PDRUtils/SingleCmd/dec_prereq_version_by.pm',
    'App/PDRUtils/SingleCmd/dec_prereq_version_to.pm',
    'App/PDRUtils/SingleCmd/inc_prereq_version_by.pm',
    'App/PDRUtils/SingleCmd/inc_prereq_version_to.pm',
    'App/PDRUtils/SingleCmd/list_prereqs.pm',
    'App/PDRUtils/SingleCmd/remove_prereq.pm',
    'App/PDRUtils/SingleCmd/set_prereq_version_to.pm',
    'App/PDRUtils/SingleCmd/sort_prereqs.pm'
);

my @scripts = (
    'script/pdrutil',
    'script/pdrutil-multi'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

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


