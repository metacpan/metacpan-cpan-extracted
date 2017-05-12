use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 27 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/FilterOrgByHeadlines.pm',
    'App/ListOrgAnniversaries.pm',
    'App/ListOrgHeadlines.pm',
    'App/ListOrgHeadlinesFast.pm',
    'App/ListOrgTodos.pm',
    'App/OrgUtils.pm'
);

my @scripts = (
    'bin/count-done-org-todos',
    'bin/count-org-headlines-fast',
    'bin/count-org-todos',
    'bin/count-org-todos-fast',
    'bin/count-undone-org-todos',
    'bin/dump-org-structure',
    'bin/filter-org-by-headlines',
    'bin/list-org-anniversaries',
    'bin/list-org-headlines',
    'bin/list-org-headlines-fast',
    'bin/list-org-priorities',
    'bin/list-org-tags',
    'bin/list-org-todo-states',
    'bin/list-org-todos',
    'bin/list-org-todos-fast',
    'bin/move-done-todos',
    'bin/org-to-html',
    'bin/org-to-html-wordpress',
    'bin/org2html',
    'bin/org2html-wp',
    'bin/stat-org-document'
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


