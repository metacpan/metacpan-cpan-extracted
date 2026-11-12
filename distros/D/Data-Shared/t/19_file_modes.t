use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use Fcntl ();
use Data::Shared;

my $parent = tempdir(CLEANUP => 1);
my $dir    = "$parent/root";

my $umask = umask 0;            # worst case: nothing masked off
my $root  = Data::Shared->new($dir);
my $mounted = eval { $root->mount('cache', 'hashmap:ii', undef, 64); 1 };
my $err = $@;
umask $umask;
plan skip_all => "backend unavailable: $err" unless $mounted;

sub mode_of {
    my ($path) = @_;
    my @st = stat $path or return undef;
    return $st[2] & 07777;
}

# `undef & 077` is 0, so a missing path would pass as owner-only.
sub is_owner_only {
    my ($path, $label) = @_;
    my $mode = mode_of($path);
    ok defined $mode, "$label exists" or return;
    is $mode & 077, 0, "$label is owner-only"
        or diag sprintf('%s mode is %04o', $label, $mode);
}

is_owner_only($dir, 'root directory');

subtest 'publishing a manifest keeps the mode it already had' => sub {
    my $shared = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new("$shared/root");
    $r->mount('a', 'hashmap:ii', undef, 16);
    my $manifest = "$shared/root/manifest.json";
    chmod 0640, $manifest or die $!;
    is((stat $manifest)[2] & 07777, 0640, 'set group-readable by hand');
    $r->mount('b', 'hashmap:ii', undef, 16);
    is((stat $manifest)[2] & 07777, 0640, 'and a topology change preserves it');
    $r->unmount('b');
    is((stat $manifest)[2] & 07777, 0640, 'as does unmounting');
};
is_owner_only("$dir/.manifest.lock", 'manifest lock');
is_owner_only("$dir/manifest.json", 'manifest');

Data::Shared::shared_set($root, '/cache/7', 42);
is Data::Shared::shared_get($root, '/cache/7'), 42, 'root still usable';

undef $root;
my $reopened = Data::Shared->open($dir);
is Data::Shared::shared_get($reopened, '/cache/7'), 42, 'reopen still works';

{
    my $cdir = "$parent/comp";
    my $mask = umask 0;
    # Constructed inside the eval so a die cannot leak umask 0 past this block.
    my $comp;
    my $ok = eval { $comp = Data::Shared->new($cdir);
                    $comp->mount('u', ['hashmap:ss', 64, ['hashmap:ss', 8]]);
                    Data::Shared::shared_set($comp, '/u/a/k', 1); 1 };
    my $why = $@;
    umask $mask;
    ok $ok, 'a composite mounts and writes under umask 0' or diag $why;
    if ($ok) {
        for my $path ('.children', '.children/u', '.children/u/.lock') {
            is_owner_only("$cdir/$path", "$path under umask 0");
        }
        # Where perl emulates flock with fcntl, LOCK_EX on a read-only fd fails.
        undef $comp;
        my $ro_lock_works = do {
            my ($probe_fh, $probe) = File::Temp::tempfile(UNLINK => 1);
            close $probe_fh;
            open my $rfh, '<', $probe or die "probe: $!";
            my $ok = flock $rfh, Fcntl::LOCK_EX();
            flock $rfh, Fcntl::LOCK_UN() if $ok;
            $ok;
        };
        if ($ro_lock_works) {
            chmod 0444, "$cdir/.children/u/.lock";
            my $ro = eval { Data::Shared->open($cdir) };
            ok $ro, 'a store with a read-only composite lock still opens' or diag $@;
            is eval { Data::Shared::shared_get($ro, '/u/a/k') }, 1, 'and reads through it'
                if $ro;
            chmod 0600, "$cdir/.children/u/.lock";
        }
        else {
            note 'this perl cannot lock a read-only descriptor; that case is not covered here';
        }
    }
}

done_testing;
