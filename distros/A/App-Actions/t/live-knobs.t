use strict;
use warnings;
use Test::Most;
use FindBin;
use File::Spec;
use YAML::PP;

# The live tests are the part of the suite that needs a daemon, and they are
# switched on and configured from the command line and from the Real Docker on
# Windows workflow.  Every knob they read carries the LIVE_TESTING prefix, so
# there is one name to remember and one prefix to look for.  This checks that
# the tests, the documentation and the workflow all agree on it, because a
# rename applied to only some of them fails silently: a variable nobody sets
# is not an error, it just means the tests quietly use the default.

my $root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

my @live = qw(t/real-docker.t t/real-docker-preflight.t t/self_test.t);

sub slurp {
    my ($file) = @_;

    my $path = File::Spec->catfile($root, $file);
    open my $handle, '<', $path or die "cannot read '$path': $!\n";
    my $text = do { local $/; <$handle> };
    close $handle;

    return $text;
}

# The variables the live tests read that are not knobs of their own: the Docker
# command, where the daemon listens, the state directory of the fake daemon
# they fall back to, the cache record and the log directory they keep out of
# the real ones, the configuration directory that keeps the developer's own
# settings out of them, and the search path that makes the fake daemon's
# steps run the Perl under test.
my %not_a_knob = map { $_ => 1 } qw(
    DOCKER DOCKER_HOST FAKE_DOCKER_STATE
    ACTION_RUN_CACHE_FILE ACTION_RUN_LOG_DIR CONFIG_DIR PATH
);

my (%read_by, @unprefixed);
for my $file (@live) {
    my $source = slurp($file);

    while ($source =~ /\$ENV\{([A-Za-z_][A-Za-z0-9_]*)\}/g) {
        my $name = $1;

        push @{ $read_by{$name} }, $file;
        push @unprefixed, "$file reads \$ENV{$name}"
            unless $not_a_knob{$name}
            || $name =~ /\ALIVE_TESTING(?:_[A-Z0-9]+)*\z/;
    }
}

is_deeply(
    \@unprefixed,
    [],
    'every knob the live tests read carries the LIVE_TESTING prefix',
);

# The knobs that exist, so that one added without a prefix above and one
# dropped without being removed from the documentation both show up here.
my @knobs = sort grep { /\ALIVE_TESTING/ } keys %read_by;

is_deeply(
    \@knobs,
    [ 'LIVE_TESTING', 'LIVE_TESTING_IMAGE' ],
    'the live tests read LIVE_TESTING and LIVE_TESTING_IMAGE',
);

# A knob nobody documents is a knob nobody sets.  The documentation and the
# workflow are checked when they are there, and skipped in a copy of the suite
# that does not carry them.
for my $document (qw(README.md lib/App/Actions.pm)) {
    SKIP: {
        skip "a copy of the suite has no $document to read", scalar @knobs
            unless -e File::Spec->catfile($root, $document);

        my $text = slurp($document);

        # The longer name contains the shorter one, so a mention of
        # LIVE_TESTING_IMAGE is not a mention of LIVE_TESTING.
        ok($text =~ /\Q$_\E(?![A-Z0-9_])/, "$document names $_") for @knobs;
    }
}

# The workflow that runs the live tests on Windows sets them itself, so a knob
# renamed in the tests but not there would leave that job on the default image.
my $workflow = '.github/workflows/real-docker-windows.yml';

SKIP: {
    skip 'a copy of the suite has no workflow to read', 1
        unless -e File::Spec->catfile($root, $workflow);

    my $loaded = YAML::PP->new->load_string(slurp($workflow));
    my $environment = $loaded->{jobs}{'real-docker'}{env} || {};

    my @unset = grep { !exists $environment->{$_} } @knobs;

    is_deeply(
        \@unset,
        [],
        'the Real Docker on Windows workflow sets every live knob',
    );
    diag "the workflow does not set: $_\n" for @unset;
}

# The live path has to run somewhere other than a developer's machine: a job
# that sets LIVE_TESTING and runs the self test is what puts it on a daemon in
# CI, and without one the live half is only ever checked by hand.
SKIP: {
    my $workflows = File::Spec->catdir($root, '.github', 'workflows');

    skip 'a copy of the suite has no workflows to read', 1 unless -d $workflows;

    opendir my $directory, $workflows or die "cannot read '$workflows': $!\n";
    my @names = sort grep { /\.ya?ml\z/ } readdir $directory;
    closedir $directory;

    my @running_live;
    for my $name (@names) {
        my $loaded = eval {
            YAML::PP->new->load_string(
                slurp(File::Spec->catfile('.github', 'workflows', $name)),
            );
        };
        next unless $loaded && ref $loaded->{jobs} eq 'HASH';

        for my $id (sort keys %{ $loaded->{jobs} }) {
            my $job = $loaded->{jobs}{$id};
            next unless ref $job eq 'HASH';

            my $environment = $job->{env} || {};
            next unless defined $environment->{LIVE_TESTING}
                && "$environment->{LIVE_TESTING}" eq '1';

            my $runs_self_test = grep {
                ref $_ eq 'HASH' && defined $_->{run} && $_->{run} =~ /t\/self_test\.t/
            } @{ ref $job->{steps} eq 'ARRAY' ? $job->{steps} : [] };

            push @running_live, "$name: $id" if $runs_self_test;
        }
    }

    ok(scalar @running_live,
        'a workflow runs the self test with LIVE_TESTING set, so the live path runs in CI');
    diag "workflows running the live self test: @running_live\n" if @running_live;
}

done_testing;
