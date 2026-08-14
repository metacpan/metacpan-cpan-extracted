use strict;
use warnings;
use Test::More;

my $dockerfile = 'Dockerfile';
ok( -f $dockerfile, 'Dockerfile exists' ) or BAIL_OUT('Dockerfile missing');

open my $fh, '<', $dockerfile or BAIL_OUT("Could not open $dockerfile: $!");
my $content = do { local $/; <$fh> };
close $fh;

like( $content, qr/AS runtime-root\b/, 'Dockerfile defines a runtime-root target' );
like( $content, qr/AS runtime-user\b/, 'Dockerfile defines a runtime-user target' );
like(
    $content,
    qr/COPY docker\/karr-entrypoint\.sh \/usr\/local\/bin\/karr-entrypoint\.sh/,
    'runtime image copies the ownership-adjusting entrypoint',
);
like(
    $content,
    qr/ENTRYPOINT \["karr-entrypoint\.sh"\]/,
    'root runtime uses the dynamic karr entrypoint',
);
like(
    $content,
    qr/\bUSER karr\b/,
    'user runtime ends as the fixed non-root karr user',
);
like(
    $content,
    qr/\bARG KARR_UID="?1000"?/,
    'Dockerfile exposes a default build-time KARR_UID argument',
);
like(
    $content,
    qr/\bARG KARR_GID="?1000"?/,
    'Dockerfile exposes a default build-time KARR_GID argument',
);

# runtime-user's `useradd -m -d /home/karr ...` creates that home directory
# itself. If runtime-base's mkdir also creates it first, useradd finds it
# already there and, instead of making it, prints:
#   useradd: warning: the home directory /home/karr already exists.
#   useradd: Not copying any file from skel directory into it.
# and silently skips the /etc/skel copy on every image build. Isolate each
# stage's body (a plain `/home/karr` grep would false-positive on the
# `ENV HOME=/home/karr` and `-d /home/karr` lines that legitimately live
# elsewhere in the file) so the checks below can't be fooled by those, and
# strip comment lines out of each stage body too — the invariant is about
# what the stage *does*, not about prose that happens to mention mkdir or
# /home/karr while explaining why it doesn't.
my ($runtime_base_stage) = $content =~ /^FROM\s+\S+\s+AS\s+runtime-base\b(.*?)(?=^FROM\s|\z)/ms;
ok( $runtime_base_stage, 'found the runtime-base stage body' )
    or BAIL_OUT('could not isolate the runtime-base stage to check its mkdir');
$runtime_base_stage = join "\n", grep { !/^\s*#/ } split /\n/, $runtime_base_stage;

like(
    $runtime_base_stage,
    qr/^RUN mkdir -p .*\/work/m,
    'runtime-base still creates /work',
);
unlike(
    $runtime_base_stage,
    qr/mkdir[^\n]*\/home\/karr/,
    'runtime-base must not pre-create /home/karr (would make useradd -m warn and skip /etc/skel)',
);

# The comment above the apt-get line explains *why* openssh-client is there
# and says "ssh" several times, so matching against $content (comments
# included) would keep passing even if the package were dropped from the
# install line. Check the comment-stripped stage body instead, and only
# require the package to appear somewhere in that particular apt-get install
# invocation -- not at a fixed position in the list, so re-sorting the
# packages isn't a regression.
like(
    $runtime_base_stage,
    qr/RUN apt-get update.*?openssh-client.*?rm -rf \/var\/lib\/apt\/lists/s,
    'runtime-base installs an ssh client so the git-CLI fallback for ssh:// remotes '
        . '(ssh-config/ProxyCommand cases libgit2 cannot handle) has an ssh binary (ticket #134)',
);

my ($runtime_user_stage) = $content =~ /^FROM\s+\S+\s+AS\s+runtime-user\b(.*?)(?=^FROM\s|\z)/ms;
ok( $runtime_user_stage, 'found the runtime-user stage body' )
    or BAIL_OUT('could not isolate the runtime-user stage to check its useradd');
$runtime_user_stage = join "\n", grep { !/^\s*#/ } split /\n/, $runtime_user_stage;

like(
    $runtime_user_stage,
    qr/useradd\s+-m\b/,
    'runtime-user keeps useradd -m so it actually creates and populates /home/karr',
);

# docker/karr-entrypoint.sh: the second half of ticket #134. openssh-client
# alone wasn't enough -- the root runtime image gosu's down to whoever owns
# /work, a host uid the image knows nothing about, and ssh looks itself up
# with getpwuid(), refusing to start with "No user exists for uid 1000" when
# that uid has no /etc/passwd entry. The fix appends one before the exec
# gosu line; after that point nothing else in the script runs, so the entry
# must land *before* it, not just somewhere in the file. Strip comments
# first -- the comment above the fix quotes "No user exists for uid" and
# names `getent passwd`, so a naive match on the whole file would keep
# passing even if the actual guard/append code were gutted.
my $entrypoint = 'docker/karr-entrypoint.sh';
ok( -f $entrypoint, 'karr-entrypoint.sh exists' )
    or BAIL_OUT('docker/karr-entrypoint.sh missing');

open my $efh, '<', $entrypoint or BAIL_OUT("Could not open $entrypoint: $!");
my @entrypoint_lines = grep { !/^\s*#/ } split /\n/, do { local $/; <$efh> };
close $efh;

my $find_line = sub {
    my ($re) = @_;
    for my $i ( 0 .. $#entrypoint_lines ) {
        return $i if $entrypoint_lines[$i] =~ $re;
    }
    return undef;
};

my $guard_idx  = $find_line->(qr/getent passwd/);
my $append_idx = $find_line->(qr{>>\s*/etc/passwd\b});
my $exec_idx   = $find_line->(qr/^\s*exec\s+gosu\b/);

ok( defined $guard_idx,  'entrypoint checks getent passwd for the target uid' );
ok( defined $append_idx, 'entrypoint appends a passwd entry to /etc/passwd' );
ok( defined $exec_idx,   'entrypoint execs gosu to drop privileges' );

if ( defined $append_idx ) {
    like( $entrypoint_lines[$append_idx], qr/target_uid/, 'appended passwd entry carries the target uid' );
    like( $entrypoint_lines[$append_idx], qr/target_gid/, 'appended passwd entry carries the target gid' );
}

SKIP: {
    skip 'could not locate both the passwd-entry append and the exec gosu line', 2
        unless defined $append_idx && defined $exec_idx;

    cmp_ok(
        $append_idx, '<', $exec_idx,
        'passwd entry for the target uid is appended before exec gosu drops privileges '
            . '-- appending it after would run too late for ssh to see it (ticket #134)',
    );
    cmp_ok(
        $guard_idx, '<', $exec_idx,
        'the getent guard around the passwd-entry append also runs before exec gosu',
    );
}

done_testing;
