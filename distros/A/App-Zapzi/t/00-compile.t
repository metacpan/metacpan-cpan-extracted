use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 25 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/Zapzi.pm',
    'App/Zapzi/Articles.pm',
    'App/Zapzi/Config.pm',
    'App/Zapzi/Database.pm',
    'App/Zapzi/Database/Schema.pm',
    'App/Zapzi/Database/Schema/Article.pm',
    'App/Zapzi/Database/Schema/ArticleText.pm',
    'App/Zapzi/Database/Schema/Config.pm',
    'App/Zapzi/Database/Schema/Folder.pm',
    'App/Zapzi/Distribute.pm',
    'App/Zapzi/Distributors/Copy.pm',
    'App/Zapzi/Distributors/Email.pm',
    'App/Zapzi/Distributors/Script.pm',
    'App/Zapzi/FetchArticle.pm',
    'App/Zapzi/Fetchers/File.pm',
    'App/Zapzi/Fetchers/POD.pm',
    'App/Zapzi/Fetchers/URL.pm',
    'App/Zapzi/Folders.pm',
    'App/Zapzi/Publish.pm',
    'App/Zapzi/Publishers/EPUB.pm',
    'App/Zapzi/Publishers/HTML.pm',
    'App/Zapzi/Publishers/MOBI.pm',
    'App/Zapzi/Transform.pm',
    'App/Zapzi/UserConfig.pm'
);

my @scripts = (
    'bin/zapzi'
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


