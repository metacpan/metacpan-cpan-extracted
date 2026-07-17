#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP qw(decode_json);

use Concierge::Desk::Setup;
use Concierge;
use Concierge::Desk::UnavailableComponent;

# ==============================================================================
# Fake component classes local to this file, used across multiple subtests
# to exercise the 'promote' mechanism (build_desk() validation/persistence
# and open_desk() trust-only replay) in isolation.
# ==============================================================================

package Fake::Broad::Component {
    # A component with a mix of methods: some meant to be promoted,
    # some not, plus a setup() that reports whether it saw a 'promote'
    # key (it should never see one -- build_desk() must exclude it).
    sub new ($class, $payload = undef) {
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return {
            success     => 1,
            message     => 'fake broad setup ok',
            saw_promote => (exists $config->{promote} ? 1 : 0),
            dir         => $config->{dir},
        };
    }
    sub get_signal_report ($self, @args) {
        return { success => 1, message => 'signal report', args => [@args] };
    }
    sub fetch_signal_report ($self, @args) {
        return { success => 1, message => 'fetch signal report', args => [@args] };
    }
    sub internal_only ($self) {
        return { success => 1, message => 'internal only, not promoted' };
    }
    sub gamma ($self) {
        return { success => 1, message => 'gamma method' };
    }
}

package Fake::FlakyPromoted::Component {
    # setup() succeeds at build time (bare new()); new($payload) dies
    # at open_desk() runtime -- used to confirm promoted forwarding
    # subs are still installed for an UnavailableComponent stand-in.
    sub new ($class, $payload = undef) {
        die "Fake::FlakyPromoted::Component deliberately dies in new()\n" if defined $payload;
        return bless {}, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub some_method ($self, @args) {
        return { success => 1, message => 'ok', args => [@args] };
    }
}

$INC{'Fake/Broad/Component.pm'}         = 1;
$INC{'Fake/FlakyPromoted/Component.pm'} = 1;

sub base_desk_config ($desk_dir, $components) {
    return {
        base_dir   => $desk_dir,
        auth       => { backend => 'pwd' },
        sessions   => { backend => 'database' },
        users      => { backend => 'database', include_standard_fields => [] },
        components => $components,
    };
}

# ==============================================================================
# build_desk() -- shape acceptance and persistence
# ==============================================================================

subtest 'build_desk(): plain-name (arrayref) promotion accepted and persisted' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => ['get_signal_report'],
            },
        })
    );
    ok $build->{success}, 'build_desk succeeds' or diag $build->{message};
    is $build->{config}{components}{reports}{promote}, ['get_signal_report'],
        'promote persisted verbatim (arrayref form)';
    ok $build->{config}{components}{reports}{payload}{success}, 'setup() payload recorded';
};

subtest 'build_desk(): aliased (hashref) promotion accepted and persisted' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => { get_signal_report => 'fetch_signal_report' },
            },
        })
    );
    ok $build->{success}, 'build_desk succeeds' or diag $build->{message};
    is $build->{config}{components}{reports}{promote},
        { get_signal_report => 'fetch_signal_report' },
        'promote persisted verbatim (hashref form)';
};

subtest 'build_desk(): two components promoting the same top-level name fails' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            alpha => {
                class   => 'Fake::Broad::Component',
                dir     => 'alpha',
                promote => { shared_name => 'get_signal_report' },
            },
            beta => {
                class   => 'Fake::Broad::Component',
                dir     => 'beta',
                promote => { shared_name => 'fetch_signal_report' },
            },
        })
    );
    ok !$build->{success}, 'build fails on name collision between two components';
    like $build->{message}, qr/alpha/, 'error message names one colliding component';
    like $build->{message}, qr/beta/, 'error message names the other colliding component';
    like $build->{message}, qr/shared_name/, 'error message names the collided top-level name';
};

subtest 'build_desk(): promoted name colliding with a core Concierge method fails' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => { login_user => 'get_signal_report' },
            },
        })
    );
    ok !$build->{success}, 'build fails when promote would shadow a core method';
    like $build->{message}, qr/login_user/, 'error message names the collided core method';
};

subtest 'build_desk(): promoted name colliding with another component accessor fails' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            gamma => {
                class => 'Fake::Broad::Component',
                dir   => 'gamma',
            },
            delta => {
                class   => 'Fake::Broad::Component',
                dir     => 'delta',
                promote => { gamma => 'get_signal_report' },
            },
        })
    );
    ok !$build->{success}, 'build fails when promote would shadow another component accessor';
    like $build->{message}, qr/gamma/, 'error message names the collided accessor name';
    like $build->{message}, qr/delta/, 'error message names the promoting component';
};

subtest 'build_desk(): unknown/typo\'d promoted method fails' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => ['no_such_method'],
            },
        })
    );
    ok !$build->{success}, 'build fails when promoted method does not exist on the component';
    like $build->{message}, qr/no_such_method/, 'error message names the unknown method';
    like $build->{message}, qr/reports/, 'error message names the component';
};

subtest 'build_desk(): promote shape validation' => sub {
    my $desk_dir1 = tempdir(CLEANUP => 1);
    my $build1 = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir1, {
            reports => { class => 'Fake::Broad::Component', dir => 'reports', promote => 'oops' },
        })
    );
    ok !$build1->{success}, 'non-array/hash promote fails';
    like $build1->{message}, qr/arrayref or hashref/, 'error message explains expected shape';

    my $desk_dir2 = tempdir(CLEANUP => 1);
    my $build2 = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir2, {
            reports => { class => 'Fake::Broad::Component', dir => 'reports', promote => [ {} ] },
        })
    );
    ok !$build2->{success}, 'array containing a non-string entry fails';

    my $desk_dir3 = tempdir(CLEANUP => 1);
    my $build3 = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir3, {
            reports => { class => 'Fake::Broad::Component', dir => 'reports', promote => { foo => [] } },
        })
    );
    ok !$build3->{success}, 'hash containing a non-string value fails';
};

subtest 'build_desk(): promote excluded from setup() args' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => ['get_signal_report'],
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    is $build->{config}{components}{reports}{payload}{saw_promote}, 0,
        'setup() never received a promote key';
};

subtest 'build_desk(): both promote forms persist verbatim into concierge.conf' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            plain => {
                class   => 'Fake::Broad::Component',
                dir     => 'plain',
                promote => ['get_signal_report'],
            },
            aliased => {
                class   => 'Fake::Broad::Component',
                dir     => 'aliased',
                promote => { report_alias => 'fetch_signal_report' },
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};

    my $conf_file = File::Spec->catfile($desk_dir, 'concierge.conf');
    open my $fh, '<', $conf_file or die "Cannot read $conf_file: $!";
    local $/;
    my $saved = decode_json(<$fh>);
    close $fh;

    is $saved->{components}{plain}{promote}, ['get_signal_report'],
        'arrayref-form promote round-trips verbatim via concierge.conf';
    is $saved->{components}{aliased}{promote}, { report_alias => 'fetch_signal_report' },
        'hashref-form promote round-trips verbatim via concierge.conf';
};

# ==============================================================================
# open_desk() -- trust-only replay
# ==============================================================================

subtest 'open_desk(): plain and aliased promotion forward correctly' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => ['get_signal_report'],
            },
            reports2 => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports2',
                promote => { report_alias => 'fetch_signal_report' },
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds' or diag $open->{message};
    my $c = $open->{concierge};

    is $c->get_signal_report('x'), $c->{reports}->get_signal_report('x'),
        'plain promotion: sugar call matches escape-hatch call';
    is $c->report_alias('y'), $c->{reports2}->fetch_signal_report('y'),
        'aliased promotion: sugar call matches escape-hatch call to the aliased method';
};

subtest 'open_desk(): UnavailableComponent substitution still gets promoted forwarding sub' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => {
                class    => 'Fake::FlakyPromoted::Component',
                dir      => 'flaky',
                optional => 1,
                promote  => ['some_method'],
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk still succeeds overall';
    my $c = $open->{concierge};
    isa_ok $c->{flaky}, ['Concierge::Desk::UnavailableComponent'],
        'failed optional component substituted with UnavailableComponent';

    ok $c->can('some_method'), 'promoted forwarding sub was installed despite substitution';
    my $result = $c->some_method('z');
    ok !$result->{success}, 'calling the promoted sub returns the standard unavailable failure hashref';
    like $result->{message}, qr/unavailable/i, 'message explains the component is unavailable';
};

subtest 'open_desk(): non-promoted method reachable only via accessor, not via $concierge->method' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class   => 'Fake::Broad::Component',
                dir     => 'reports',
                promote => ['get_signal_report'],
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds';
    my $c = $open->{concierge};

    ok $c->{reports}->internal_only->{success}, 'non-promoted method reachable via bare hash access';
    ok $c->reports->internal_only->{success}, 'non-promoted method reachable via bare accessor';
    ok !$c->can('internal_only'), 'non-promoted method is NOT reachable directly on $concierge';
};

done_testing;
