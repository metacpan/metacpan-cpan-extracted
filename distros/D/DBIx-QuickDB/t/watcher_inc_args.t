use strict;
use warnings;

use Test2::V0;
use File::Temp qw/tempdir/;
use File::Path qw/make_path/;
use File::Spec();
use Cwd qw/abs_path/;

use DBIx::QuickDB::Watcher;

# The re-exec'd watcher must load the same Watcher.pm its parent did. A
# hardcoded relative '-Ilib' meant any process whose cwd held
# lib/DBIx/QuickDB/Watcher.pm silently ran a different version.

# Run a child perl in a directory, with extra env and stderr merged into stdout.
# No shell: list-form exec means a path containing a quote cannot mis-parse the
# command, which backticks did.
sub run_perl {
    my (%params) = @_;

    my $pid = open(my $fh, '-|');
    die "Could not fork: $!" unless defined $pid;

    unless ($pid) {
        if (my $dir = $params{cwd}) { chdir($dir) or die "Could not chdir to '$dir': $!" }

        my $env = $params{env} || {};
        $ENV{$_} = $env->{$_} for keys %$env;

        open(STDERR, '>&', \*STDOUT);
        exec($^X, @{$params{args}});
        die "Could not exec $^X: $!";
    }

    my $out = do { local $/; <$fh> };
    close($fh);

    return defined($out) ? $out : '';
}

my $tmp  = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
my $root = "$tmp/fakeroot";
make_path("$root/DBIx/QuickDB");

open(my $fh, '>', "$root/DBIx/QuickDB/Watcher.pm") or die "Could not write decoy: $!";
print $fh "1;\n";
close($fh);

subtest loaded_from_dir_comes_first => sub {
    local %INC = (%INC, 'DBIx/QuickDB/Watcher.pm' => "$root/DBIx/QuickDB/Watcher.pm");
    local @INC = ('/nonexistent-alpha', '/nonexistent-beta');

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args($root);

    is($args[0], "-I$root", "Directory the module was really loaded from is passed first");
    is(
        \@args,
        ["-I$root", '-I/nonexistent-alpha', '-I/nonexistent-beta'],
        "Followed by the parent's own \@INC, in order",
    );
};

subtest no_hardcoded_relative_lib => sub {
    local %INC = (%INC, 'DBIx/QuickDB/Watcher.pm' => "$root/DBIx/QuickDB/Watcher.pm");
    local @INC = ('/nonexistent-alpha');

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args($root);

    # -Ilib must never be synthesized; it may only appear when the parent
    # genuinely had it in @INC.
    ok(!(grep { $_ eq '-Ilib' } @args), "No hardcoded relative -Ilib is injected");
};

subtest relative_entries_are_absolutized => sub {
    local %INC = (%INC, 'DBIx/QuickDB/Watcher.pm' => "$root/DBIx/QuickDB/Watcher.pm");
    local @INC = ('lib', '/nonexistent-alpha');

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args($root);

    # Hygiene, not a guarantee: the watcher shares the caller's cwd, so a
    # relative entry would resolve the same forwarded verbatim. What pins the
    # module is $LOADED_FROM coming first, covered by the decoy subtests.
    my $abs = abs_path('lib');

    ok(!(grep { $_ eq '-Ilib' } @args), "The relative entry is not forwarded verbatim");
    ok((grep { $_ eq "-I$abs" } @args), "It is forwarded resolved against the parent's cwd");

    # A path that does not resolve has nothing better to become, and is kept.
    ok((grep { $_ eq '-I/nonexistent-alpha' } @args), "An unresolvable entry is passed through as-is");
};

subtest non_string_inc_entries_are_dropped => sub {
    local %INC = (%INC, 'DBIx/QuickDB/Watcher.pm' => "$root/DBIx/QuickDB/Watcher.pm");
    local @INC = (sub { }, ['array', 'hook'], bless({}, 'Some::Hook'), '/nonexistent-alpha');

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args($root);

    # Stringifying a hook would hand the child -ICODE(0x...).
    is(
        \@args,
        ["-I$root", '-I/nonexistent-alpha'],
        "Coderef/arrayref/object \@INC hooks are dropped, not stringified",
    );
};

subtest deduplicates_the_derived_root => sub {
    local %INC = (%INC, 'DBIx/QuickDB/Watcher.pm' => "$root/DBIx/QuickDB/Watcher.pm");
    local @INC = ($root, '/nonexistent-alpha', $root);

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args($root);

    is(
        scalar(grep { $_ eq "-I$root" } @args),
        1,
        "The derived root is not repeated when \@INC already contains it",
    );
};

subtest falls_back_when_no_directory_can_be_derived => sub {
    # A module loaded through an @INC hook has no real directory behind it, so
    # the load-time capture comes out undef.
    local @INC = ('/nonexistent-alpha', '/nonexistent-beta');

    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args(undef);

    is(
        \@args,
        ['-I/nonexistent-alpha', '-I/nonexistent-beta'],
        "Falls back to the filtered \@INC alone rather than passing a bogus dir",
    );
};

subtest real_process_resolution => sub {
    # No argument: the real load-time capture.
    my @args = DBIx::QuickDB::Watcher::_watcher_inc_args();

    # The property, never a particular directory: comparing against
    # abs_path('lib') passes under prove -Ilib and fails under make test, which
    # loads from blib/lib.
    if (defined $args[0]) {
        my ($dir) = $args[0] =~ m/\A-I(.*)\z/s;

        ok(File::Spec->file_name_is_absolute($dir), "The load-time capture is an absolute path")
            or diag("got '$dir' -- a relative path would re-resolve against the watcher's cwd");

        ok(-f "$dir/DBIx/QuickDB/Watcher.pm", "It really is the directory this module was loaded from")
            or diag("'$dir' does not contain DBIx/QuickDB/Watcher.pm");
    }

    ok(@args, "Produced some -I arguments");
    ok(!(grep { !m/^-I/ } @args), "Every argument is an -I flag");
    ok(!(grep { m/^-I(CODE|ARRAY|HASH)\(/ } @args), "No stringified refs leaked in");
};

subtest decoy_lib_in_cwd_is_not_loaded => sub {
    # Covers that watch() USES _watcher_inc_args: reverting the exec to a
    # hardcoded -Ilib left every subtest above passing.
    # The decoy is a working copy that marks the filesystem when loaded.
    #
    # skip_all, not a bare return: a subtest that asserts nothing lands at
    # "1..0", which Test2 reports as a failure.
    skip_all "Needs the Unix watcher (no POSIX signals on $^O)" if $^O eq 'MSWin32';

    my $real_lib = abs_path('lib');
    my $test_lib = abs_path('t/lib');

    # skip_all, not skip: skip ends in "last SKIP", which throws inside a
    # subtest sub that has no such label.
    skip_all "Cannot locate lib/ and t/lib from this cwd"
        unless $real_lib && $test_lib && -d $real_lib && -d $test_lib;

    my $cwd  = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $mark = "$cwd/DECOY-WAS-LOADED";
    my $ddir = "$cwd/db";
    make_path("$cwd/lib/DBIx/QuickDB", $ddir);

    my $src = do {
        open(my $in, '<', "$real_lib/DBIx/QuickDB/Watcher.pm") or die "Could not read Watcher.pm: $!";
        local $/;
        <$in>;
    };

    $src =~ s/^(package DBIx::QuickDB::Watcher;)/$1\nBEGIN { if (my \$f = \$ENV{QDB_DECOY_MARKER}) { open(my \$m, '>', \$f) and close(\$m) } }/m
        or die "Could not inject the decoy marker";

    open(my $out, '>', "$cwd/lib/DBIx/QuickDB/Watcher.pm") or die "Could not write decoy: $!";
    print $out $src;
    close($out);

    my $script = join('; ',
        'use QDB::FakeDriver',
        'my $db = QDB::FakeDriver->new(dir => $ARGV[0], exit_code => 0, cleanup => 0, autostart => 0)',
        'eval { $db->start; 1 }',
        'print "CHILD_DONE\n"',
    );

    my $got = run_perl(
        cwd  => $cwd,
        env  => {QDB_DECOY_MARKER => $mark, QDB_START_TIMEOUT => 5},
        args => ["-I$real_lib", "-I$test_lib", '-e', $script, $ddir],
    );

    like($got, qr/CHILD_DONE/, "The child ran to completion");
    ok(!-e $mark, "The watcher did NOT load the decoy Watcher.pm sitting in its CWD")
        or diag("Decoy loaded -- watcher is running a different version than its parent.\nChild output:\n$got");
};

subtest chdir_after_load_does_not_reach_a_decoy => sub {
    # The parent loads through a RELATIVE @INC entry (what prove -Ilib gives)
    # and only then chdirs somewhere holding its own Watcher.pm. Resolving
    # %INC at spawn time rather than at load time would resolve it against the
    # new cwd and reach that decoy.
    skip_all "Needs the Unix watcher (no POSIX signals on $^O)" if $^O eq 'MSWin32';

    my $real_lib = abs_path('lib');
    my $test_lib = abs_path('t/lib');

    skip_all "Cannot locate lib/ and t/lib from this cwd"
        unless $real_lib && $test_lib && -d $real_lib && -d $test_lib;

    # A: real modules, reachable relatively. B: the decoy, chdir'd into later.
    my $a    = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $b    = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $mark = "$b/DECOY-WAS-LOADED";
    my $ddir = "$b/db";
    make_path("$b/lib/DBIx/QuickDB", $ddir);

    skip_all "Cannot symlink (needed to make lib/ reachable relatively)"
        unless symlink($real_lib, "$a/lib") && symlink($test_lib, "$a/tlib");

    my $src = do {
        open(my $in, '<', "$real_lib/DBIx/QuickDB/Watcher.pm") or die "Could not read Watcher.pm: $!";
        local $/;
        <$in>;
    };
    $src =~ s/^(package DBIx::QuickDB::Watcher;)/$1\nBEGIN { if (my \$f = \$ENV{QDB_DECOY_MARKER}) { open(my \$m, '>', \$f) and close(\$m) } }/m
        or die "Could not inject the decoy marker";

    open(my $out, '>', "$b/lib/DBIx/QuickDB/Watcher.pm") or die "Could not write decoy: $!";
    print $out $src;
    close($out);

    my $script = join('; ',
        'use QDB::FakeDriver',
        'use DBIx::QuickDB::Watcher',
        'chdir($ARGV[1]) or die "chdir: $!"',
        'my $db = QDB::FakeDriver->new(dir => $ARGV[0], exit_code => 0, cleanup => 0, autostart => 0)',
        'eval { $db->start; 1 }',
        'print "CHILD_DONE\n"',
    );

    # Relative -I on purpose: that is what makes %INC relative too.
    my $got = run_perl(
        cwd  => $a,
        env  => {QDB_DECOY_MARKER => $mark, QDB_START_TIMEOUT => 5},
        args => ['-Ilib', '-Itlib', '-e', $script, $ddir, $b],
    );

    like($got, qr/CHILD_DONE/, "The child ran to completion");
    ok(!-e $mark, "A chdir after load does not make the watcher pick up a decoy")
        or diag("Decoy loaded after chdir -- the load-from directory was resolved at spawn time rather than at load time.\nChild output:\n$got");
};

done_testing;
