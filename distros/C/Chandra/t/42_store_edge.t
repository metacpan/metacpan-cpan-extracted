#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);

use_ok('Chandra::Store');

my $dir = tempdir(CLEANUP => 1);
sub sp { "$dir/$_[0].json" }

# ---- Corrupt JSON recovery ----

{
    my $path = sp('corrupt');

    # Prime with valid data
    my $s = Chandra::Store->new(path => $path);
    $s->set('ok', 1);

    # Corrupt the file
    open(my $fh, '>', $path) or die $!;
    print $fh 'THIS IS NOT JSON }{{{';
    close $fh;

    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ /corrupt/i };

    my $s2 = Chandra::Store->new(path => $path);
    is($s2->get('ok'), undef, 'corrupt file: data starts fresh');
    is($warned, 1, 'corrupt file: emits warning');
}

# ---- Empty file ----

{
    my $path = sp('empty');
    open(my $fh, '>', $path) or die $!;
    close $fh;

    my $s;
    eval { $s = Chandra::Store->new(path => $path) };
    ok(!$@, 'empty file does not throw');
    is_deeply($s->all, {}, 'empty file starts with empty store');
}

# ---- Missing directory created automatically ----

{
    my $nested = "$dir/deep/nested/dir/store.json";
    my $s = Chandra::Store->new(path => $nested);
    $s->set('x', 1);
    ok(-f $nested, 'deeply nested directory and file created automatically');
}

# ---- Very deep nesting ----

{
    my $s = Chandra::Store->new(path => sp('deep'));
    my $key = join('.', ('a') x 20);
    $s->set($key, 'bottom');
    is($s->get($key), 'bottom', '20-level deep nesting set/get');

    my $s2 = Chandra::Store->new(path => sp('deep'));
    is($s2->get($key), 'bottom', 'deep nesting persists');
}

# ---- Special characters in values ----

{
    my $s = Chandra::Store->new(path => sp('special'));
    my $val = "line1\nline2\ttab\"quote\\back";
    $s->set('special', $val);
    my $s2 = Chandra::Store->new(path => sp('special'));
    is($s2->get('special'), $val, 'special characters in values survive round-trip');
}

# ---- Dot in value does not confuse traversal ----

{
    my $s = Chandra::Store->new(path => sp('dotval'));
    $s->set('url', 'https://example.com');
    is($s->get('url'), 'https://example.com', 'dot in value not treated as path separator');
}

# ---- Setting a scalar then trying to traverse through it ----

{
    my $s = Chandra::Store->new(path => sp('clash'), auto_save => 0);
    $s->set('foo', 'scalar');
    # foo is a string, not a hash — setting foo.bar should die
    eval { $s->set('foo.bar', 'x') };
    like($@, qr/not a hash/i, 'intermediate scalar blocks traversal');
}

# ---- Large value ----

{
    my $s = Chandra::Store->new(path => sp('large'));
    my $big = 'x' x 100_000;
    $s->set('blob', $big);
    my $s2 = Chandra::Store->new(path => sp('large'));
    is($s2->get('blob'), $big, '100KB value round-trips');
}

# ---- Boolean-like values ----

{
    my $s = Chandra::Store->new(path => sp('bool'));
    $s->set('t', 1);
    $s->set('f', 0);
    $s->set('n', undef);

    my $s2 = Chandra::Store->new(path => sp('bool'));
    is($s2->get('t'), 1,     'truthy 1 round-trips');
    is($s2->get('f'), 0,     'falsy 0 round-trips');
    is($s2->get('n'), undef, 'undef round-trips as undef or null');
}

# ---- Atomic write: tmp file removed on success ----

{
    my $path = sp('atomic');
    my $s = Chandra::Store->new(path => $path);
    $s->set('v', 1);
    my $tmp_glob = "$path.tmp.*";
    my @tmps = glob $tmp_glob;
    is(scalar @tmps, 0, 'no .tmp file left after successful save');
}

# ---- Concurrent read/write with fork ----

SKIP: {
    skip 'fork not available', 4 unless $^O ne 'MSWin32';

    my $path = sp('concurrent');
    my $s = Chandra::Store->new(path => $path);
    $s->set('counter', 0);

    my $writers = 5;
    my @pids;

    for (1 .. $writers) {
        my $pid = fork();
        die "fork failed: $!" unless defined $pid;
        if ($pid == 0) {
            # Child: open its own store handle and increment counter
            for (1 .. 10) {
                my $child_s = Chandra::Store->new(path => $path);
                my $val = $child_s->get('counter') // 0;
                $child_s->set('counter', $val + 1);
            }
            exit 0;
        }
        push @pids, $pid;
    }

    for my $pid (@pids) {
        waitpid($pid, 0);
        is($?, 0, "writer child $pid exited cleanly");
    }

    # File must still be valid JSON after concurrent writes
    my $final = Chandra::Store->new(path => $path);
    my $all = $final->all;
    is(ref $all, 'HASH', 'store is valid hashref after concurrent writes');
    ok(defined $final->get('counter'), 'counter key exists after concurrent writes');
}

# ---- delete with dot notation preserves siblings ----

{
    my $s = Chandra::Store->new(path => sp('deldot'));
    $s->set_many({
        'a.x' => 1,
        'a.y' => 2,
        'a.z' => 3,
    });
    $s->delete('a.y');
    is($s->has('a.x'), 1, 'sibling x survives delete of y');
    is($s->has('a.z'), 1, 'sibling z survives delete of y');
    is($s->has('a.y'), 0, 'y is gone');
    is($s->has('a'),   1, 'parent a survives');
}

# ---- name-based store path ----

{
    my $name  = "chandra_test_$$";
    my $store = Chandra::Store->new(name => $name);
    like($store->path, qr/\Q$name\E/, 'name-based path contains app name');
    like($store->path, qr/store\.json$/, 'name-based path ends in store.json');
    # Cleanup
    unlink $store->path;
    my $path = $store->path;
    $path =~ s|/[^/]+$||;  # simple dirname
    rmdir($path);
}

done_testing();
