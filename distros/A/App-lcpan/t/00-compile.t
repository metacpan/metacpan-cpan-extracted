use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 78 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/lcpan.pm',
    'App/lcpan/Cmd/author_deps.pm',
    'App/lcpan/Cmd/author_deps_by_dependent_count.pm',
    'App/lcpan/Cmd/author_dists.pm',
    'App/lcpan/Cmd/author_mods.pm',
    'App/lcpan/Cmd/author_rdeps.pm',
    'App/lcpan/Cmd/author_rels.pm',
    'App/lcpan/Cmd/author_scripts.pm',
    'App/lcpan/Cmd/authors.pm',
    'App/lcpan/Cmd/authors_by_dist_count.pm',
    'App/lcpan/Cmd/authors_by_filesize.pm',
    'App/lcpan/Cmd/authors_by_mod_count.pm',
    'App/lcpan/Cmd/authors_by_mod_mention_count.pm',
    'App/lcpan/Cmd/authors_by_rdep_count.pm',
    'App/lcpan/Cmd/authors_by_rel_count.pm',
    'App/lcpan/Cmd/authors_by_script_count.pm',
    'App/lcpan/Cmd/changes.pm',
    'App/lcpan/Cmd/contents.pm',
    'App/lcpan/Cmd/copy_mod.pm',
    'App/lcpan/Cmd/copy_rel.pm',
    'App/lcpan/Cmd/copy_script.pm',
    'App/lcpan/Cmd/delete_rel.pm',
    'App/lcpan/Cmd/deps.pm',
    'App/lcpan/Cmd/deps_by_dependent_count.pm',
    'App/lcpan/Cmd/dist2author.pm',
    'App/lcpan/Cmd/dist2rel.pm',
    'App/lcpan/Cmd/dist_contents.pm',
    'App/lcpan/Cmd/dist_meta.pm',
    'App/lcpan/Cmd/dist_mods.pm',
    'App/lcpan/Cmd/dist_scripts.pm',
    'App/lcpan/Cmd/dists.pm',
    'App/lcpan/Cmd/dists_by_dep_count.pm',
    'App/lcpan/Cmd/doc.pm',
    'App/lcpan/Cmd/extract_dist.pm',
    'App/lcpan/Cmd/extract_mod.pm',
    'App/lcpan/Cmd/extract_rel.pm',
    'App/lcpan/Cmd/extract_script.pm',
    'App/lcpan/Cmd/inject.pm',
    'App/lcpan/Cmd/mentions.pm',
    'App/lcpan/Cmd/mentions_by_mod.pm',
    'App/lcpan/Cmd/mentions_by_script.pm',
    'App/lcpan/Cmd/mentions_for_all_mods.pm',
    'App/lcpan/Cmd/mentions_for_mod.pm',
    'App/lcpan/Cmd/mentions_for_script.pm',
    'App/lcpan/Cmd/mod2author.pm',
    'App/lcpan/Cmd/mod2dist.pm',
    'App/lcpan/Cmd/mod2rel.pm',
    'App/lcpan/Cmd/mod_contents.pm',
    'App/lcpan/Cmd/mods.pm',
    'App/lcpan/Cmd/mods_by_mention_count.pm',
    'App/lcpan/Cmd/mods_by_rdep_count.pm',
    'App/lcpan/Cmd/mods_from_same_dist.pm',
    'App/lcpan/Cmd/modules.pm',
    'App/lcpan/Cmd/namespaces.pm',
    'App/lcpan/Cmd/rdeps.pm',
    'App/lcpan/Cmd/related_mods.pm',
    'App/lcpan/Cmd/releases.pm',
    'App/lcpan/Cmd/rels.pm',
    'App/lcpan/Cmd/reset.pm',
    'App/lcpan/Cmd/script2author.pm',
    'App/lcpan/Cmd/script2dist.pm',
    'App/lcpan/Cmd/script2mod.pm',
    'App/lcpan/Cmd/script2rel.pm',
    'App/lcpan/Cmd/scripts.pm',
    'App/lcpan/Cmd/scripts_by_mention_count.pm',
    'App/lcpan/Cmd/scripts_from_same_dist.pm',
    'App/lcpan/Cmd/src.pm',
    'App/lcpan/Cmd/stats.pm',
    'App/lcpan/Cmd/stats_last_index_time.pm',
    'App/lcpan/Cmd/subnames_by_count.pm',
    'App/lcpan/Cmd/subs.pm',
    'App/lcpan/Cmd/update.pm',
    'App/lcpan/PodParser.pm',
    'LWP/UserAgent/Patch/FilterLcpan.pm'
);

my @scripts = (
    'script/lcpan',
    'script/lcpanm',
    'script/lcpanm-namespace',
    'script/lcpanm-script'
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


