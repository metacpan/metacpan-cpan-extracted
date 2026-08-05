#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP qw(decode_json);

use Concierge::Desk::Component;
use Concierge::Desk::DeferredComponent;
use Concierge::Desk::Setup;
use Concierge;
use Concierge::Desk::UnavailableComponent;

# ==============================================================================
# Fake components satisfying the duck-typed Concierge::Desk::Component
# contract, used to exercise the 'defer' mechanism (probe_component(),
# build_desk() tier 1b, open_desk() tier 2/3) in isolation.
# ==============================================================================

package Fake::Defer::ProbePasses::Component {
    # Implements probe(), which succeeds. Counts calls to both probe()
    # and new() so tests can assert exactly how many times each ran.
    our $probe_calls = 0;
    our $new_calls   = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub probe ($class, $payload = undef) {
        $probe_calls++;
        return { success => 1 };
    }
    sub greet ($self) {
        return { success => 1, message => 'hello from ProbePasses' };
    }
}

package Fake::Defer::ProbeFails::Component {
    # Implements probe(), which fails. new() should never be called at
    # all if probe correctly short-circuits later tiers.
    our $probe_calls = 0;
    our $new_calls   = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub probe ($class, $payload = undef) {
        $probe_calls++;
        return { success => 0, message => 'ProbeFails deliberately fails its probe' };
    }
}

package Fake::Defer::NoProbe::Component {
    # No probe() method at all -- confirms the default require-only
    # check (Concierge::Desk::Component::probe_component()) runs in its
    # place, rather than either tier being skipped.
    our $new_calls = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub greet ($self) {
        return { success => 1, message => 'hello from NoProbe' };
    }
}

$INC{'Fake/Defer/ProbePasses/Component.pm'} = 1;
$INC{'Fake/Defer/ProbeFails/Component.pm'}  = 1;
$INC{'Fake/Defer/NoProbe/Component.pm'}     = 1;

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
# Concierge::Desk::Component::probe_component() -- direct unit tests
# (plan §12 test case 15)
# ==============================================================================

subtest 'probe_component(): real probe() present is called and its result returned' => sub {
    $Fake::Defer::ProbePasses::Component::probe_calls = 0;
    my $result = Concierge::Desk::Component::probe_component(
        'Fake::Defer::ProbePasses::Component', { some => 'payload' },
    );
    ok $result->{success}, 'probe_component() reports success from the real probe()';
    is $Fake::Defer::ProbePasses::Component::probe_calls, 1, 'probe() was called exactly once';
};

subtest 'probe_component(): probe absent, class requires successfully' => sub {
    my $result = Concierge::Desk::Component::probe_component(
        'Fake::Defer::NoProbe::Component', { some => 'payload' },
    );
    ok $result->{success}, 'probe_component() falls back to require-only check and succeeds';
};

subtest 'probe_component(): probe absent, class fails to require' => sub {
    my $result = Concierge::Desk::Component::probe_component(
        'Fake::Defer::NoSuchClass::Component', { some => 'payload' },
    );
    ok !$result->{success}, 'probe_component() fails when the class cannot be required';
    ok defined $result->{message}, 'failure includes a message (the require error)';
};

# ==============================================================================
# Concierge::Desk::DeferredComponent -- direct unit tests, in isolation
# (plan §12 test case 13, no open_desk() involved)
# ==============================================================================

package Fake::Defer::Direct::Component {
    our $new_calls = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        return bless { payload => $payload }, $class;
    }
    sub greet ($self) {
        return { success => 1, message => "hello, payload was $self->{payload}{who}" };
    }
}
$INC{'Fake/Defer/Direct/Component.pm'} = 1;

package Fake::Defer::Direct::FailingComponent {
    our $new_calls = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        die "Fake::Defer::Direct::FailingComponent deliberately dies in new()\n";
    }
}
$INC{'Fake/Defer/Direct/FailingComponent.pm'} = 1;

subtest 'DeferredComponent: real new() is not called until first method call' => sub {
    $Fake::Defer::Direct::Component::new_calls = 0;

    my $comp = Concierge::Desk::DeferredComponent->new(
        name => 'thing', class => 'Fake::Defer::Direct::Component', payload => { who => 'world' },
    );
    isa_ok $comp, ['Concierge::Desk::DeferredComponent'];
    is $Fake::Defer::Direct::Component::new_calls, 0, 'real new() not yet called after construction';

    my $result = $comp->greet;
    is $Fake::Defer::Direct::Component::new_calls, 1, 'real new() called exactly once, on first use';
    is $result, { success => 1, message => 'hello, payload was world' },
        'first call delegates correctly to the newly-built real object';

    $comp->greet;
    $comp->greet;
    is $Fake::Defer::Direct::Component::new_calls, 1,
        'subsequent calls do not re-build -- free for the second (and third) use';
};

subtest 'DeferredComponent: DESTROY does not trigger the deferred build' => sub {
    $Fake::Defer::Direct::Component::new_calls = 0;

    my $comp = Concierge::Desk::DeferredComponent->new(
        name => 'thing', class => 'Fake::Defer::Direct::Component', payload => { who => 'world' },
    );
    ok lives { undef $comp }, 'own DESTROY runs cleanly at teardown instead of falling through to AUTOLOAD';
    is $Fake::Defer::Direct::Component::new_calls, 0, 'teardown never triggered the deferred build';
};

subtest 'DeferredComponent: can()/isa() caveat parity with UnavailableComponent' => sub {
    my $comp = Concierge::Desk::DeferredComponent->new(
        name => 'thing', class => 'Fake::Defer::Direct::Component', payload => {},
    );
    ok !$comp->can('greet'),
        'can() does NOT report true for AUTOLOAD-handled methods, even before the real build';
};

subtest 'DeferredComponent: first-use failure resolves to UnavailableComponent-style failure, permanently' => sub {
    $Fake::Defer::Direct::FailingComponent::new_calls = 0;

    my $comp = Concierge::Desk::DeferredComponent->new(
        name => 'flaky', class => 'Fake::Defer::Direct::FailingComponent', payload => {},
    );

    my $result = $comp->whatever_method;
    ok !$result->{success}, 'first call resolves to a graceful failure hashref, never a live crash';
    like $result->{message}, qr/flaky.*unavailable/is, 'message matches UnavailableComponent format';
    is $Fake::Defer::Direct::FailingComponent::new_calls, 1, 'the failing new() was attempted exactly once';

    my $result2 = $comp->another_method;
    ok !$result2->{success}, 'second call still returns a graceful failure';
    is $Fake::Defer::Direct::FailingComponent::new_calls, 1,
        'the failing new() is never retried -- permanent failure for the life of this instance';
};

# ==============================================================================
# build_desk() -- 'defer' validation and tier 1b build-time probe
# (plan §12 test cases 1-5)
# ==============================================================================

subtest 'build_desk() rejects defer => 1, optional => 0' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => { class => 'Fake::Defer::NoProbe::Component', dir => 'reports', defer => 1 },
        })
    );
    ok !$build->{success}, 'build fails entirely when defer is set without optional';
    like $build->{message}, qr/reports.*defer.*optional/is,
        'error message names the component and explains defer requires optional';
};

subtest 'build_desk() accepts and persists defer => 1, optional => 1' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::NoProbe::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    is $build->{config}{components}{reports}{defer}, 1, 'defer flag recorded as true in returned config';
    is $build->{config}{components}{reports}{optional}, 1, 'optional flag also recorded as true';

    my $conf_file = File::Spec->catfile($desk_dir, 'concierge.conf');
    open my $fh, '<', $conf_file or die "Cannot read $conf_file: $!";
    local $/;
    my $saved = decode_json(<$fh>);
    close $fh;
    is $saved->{components}{reports}{defer}, 1, 'defer flag persisted to concierge.conf';
};

subtest 'build_desk(): tier 1b probe failure fails the whole build, even though optional' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);
    $Fake::Defer::ProbeFails::Component::probe_calls = 0;
    $Fake::Defer::ProbeFails::Component::new_calls   = 0;

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => {
                class => 'Fake::Defer::ProbeFails::Component', dir => 'flaky',
                defer => 1, optional => 1,
            },
        })
    );
    ok !$build->{success}, 'build fails entirely when the tier 1b probe fails';
    like $build->{message}, qr/flaky/, 'error message names the failing component';
    is $Fake::Defer::ProbeFails::Component::probe_calls, 1, 'probe() was called once, at build time';
    is $Fake::Defer::ProbeFails::Component::new_calls, 1,
        'new() was called only its normal once (the bare build-time construction for setup()) -- '
        . 'tier 1a already succeeded, tier 1b stopped the build before anything further happened';
};

subtest 'build_desk(): tier 1b probe success allows the build to proceed' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);
    $Fake::Defer::ProbePasses::Component::probe_calls = 0;
    $Fake::Defer::ProbePasses::Component::new_calls   = 0;

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::ProbePasses::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    is $Fake::Defer::ProbePasses::Component::probe_calls, 1, 'probe() was called exactly once, at build time';
};

subtest 'build_desk(): tier 1b falls back to require-only check when probe() is absent' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);
    $Fake::Defer::NoProbe::Component::new_calls = 0;

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::NoProbe::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds via the default require-only check -- probe absence is not a build failure'
        or diag $build->{message};
};

# ==============================================================================
# open_desk() -- 'defer' tier 2 revalidation and tier 3 first-use wiring
# (plan §12 test cases 6-10; test case 14, the full unmodified regression of
# t/07-components.t, is covered by prove running the whole t/ directory
# rather than duplicated here)
# ==============================================================================

package Fake::Defer::FlipProbe::Component {
    # probe() behavior is controlled by a package variable so a single
    # test can build the desk with a passing probe (tier 1b succeeds)
    # and then flip it to failing before calling open_desk() -- isolating
    # tier 2 (open-time revalidation) from tier 1b (build-time probe),
    # per plan §12 test case 9's note.
    our $should_fail = 0;
    our $new_calls   = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub probe ($class, $payload = undef) {
        return $should_fail
            ? { success => 0, message => 'FlipProbe deliberately fails now' }
            : { success => 1 };
    }
    sub greet ($self) {
        return { success => 1, message => "hello, payload dir was $self->{payload}{dir}" };
    }
}
$INC{'Fake/Defer/FlipProbe/Component.pm'} = 1;

package Fake::Defer::FirstUseFails::Component {
    # probe() always passes (tiers 1b/2 never catch this one), but the
    # real new($payload) dies -- used to exercise tier 3's own failure
    # path through the full build_desk()+open_desk() pipeline. Bare
    # new() (no payload) still succeeds, so build-time tier 1a (which
    # uses a payload-less instance) is unaffected -- only the real,
    # payload-bearing construction at first use fails.
    our $new_calls = 0;
    sub new ($class, $payload = undef) {
        $new_calls++;
        die "Fake::Defer::FirstUseFails::Component deliberately dies in new()\n"
            if defined $payload;
        return bless {}, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
    sub probe ($class, $payload = undef) {
        return { success => 1 };
    }
    sub greet ($self) {
        return { success => 1, message => 'hello from FirstUseFails' };
    }
}
$INC{'Fake/Defer/FirstUseFails/Component.pm'} = 1;

subtest 'open_desk(): defer component installs DeferredComponent, real new() not yet called' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::NoProbe::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    $Fake::Defer::NoProbe::Component::new_calls = 0;   # isolate open_desk()'s own effect

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds' or diag $open->{message};
    isa_ok $open->{concierge}{reports}, ['Concierge::Desk::DeferredComponent'],
        'DeferredComponent installed, not the real class';
    is $Fake::Defer::NoProbe::Component::new_calls, 0,
        'real new() not called just from opening the desk';
};

subtest 'open_desk(): first method call on a deferred component triggers real new(), second does not re-build' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);
    $Fake::Defer::FlipProbe::Component::should_fail = 0;

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::FlipProbe::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    $Fake::Defer::FlipProbe::Component::new_calls = 0;

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds';

    my $result = $open->{concierge}->reports->greet;
    is $Fake::Defer::FlipProbe::Component::new_calls, 1, 'real new() called exactly once, on first use';
    ok $result->{success}, "the delegated call returns the real component's result";

    $open->{concierge}->reports->greet;
    is $Fake::Defer::FlipProbe::Component::new_calls, 1,
        'a second call does not re-build -- free for the second user';
};

subtest 'open_desk(): tier 2 probe failure substitutes UnavailableComponent, not DeferredComponent' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);
    $Fake::Defer::FlipProbe::Component::should_fail = 0;

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => {
                class => 'Fake::Defer::FlipProbe::Component', dir => 'flaky',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds while probe still passes' or diag $build->{message};

    # Flip the probe to failing *after* the build, isolating tier 2 from
    # tier 1b (which already passed once, at build time).
    $Fake::Defer::FlipProbe::Component::should_fail = 1;
    $Fake::Defer::FlipProbe::Component::new_calls   = 0;

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk still succeeds overall';
    isa_ok $open->{concierge}{flaky}, ['Concierge::Desk::UnavailableComponent'],
        'tier 2 probe failure substitutes UnavailableComponent directly, not DeferredComponent';

    my $result = $open->{concierge}->flaky->greet;
    ok !$result->{success}, 'calling any method returns the standard unavailable failure hashref';
    is $Fake::Defer::FlipProbe::Component::new_calls, 0,
        'real new() was never attempted -- tier 3 is unreachable once tier 2 already ruled it out';

    $Fake::Defer::FlipProbe::Component::should_fail = 0;   # reset for any later use
};

subtest "open_desk(): tier 2 probe passing is a no-op from the caller's perspective (probe() present)" => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            reports => {
                class => 'Fake::Defer::ProbePasses::Component', dir => 'reports',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds' or diag $build->{message};
    $Fake::Defer::ProbePasses::Component::probe_calls = 0;

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds';
    isa_ok $open->{concierge}{reports}, ['Concierge::Desk::DeferredComponent'],
        'DeferredComponent installed exactly as in the no-probe case';
    is $Fake::Defer::ProbePasses::Component::probe_calls, 1, 'probe() called once, at open_desk() time (tier 2)';

    my $result = $open->{concierge}->reports->greet;
    ok $result->{success}, 'first real use still works correctly';
};

# ==============================================================================
# open_desk() -- tier 3 failure hardening, through the full
# build_desk()+open_desk() pipeline (plan §12 test case 11).
# (Tier 3's basic success/failure mechanics are already covered directly
# against DeferredComponent in isolation, above; this subtest confirms
# the same guarantees hold end-to-end, via a live desk.)
# ==============================================================================

subtest 'open_desk(): tier 3 first-use failure resolves to a graceful failure, permanently, end-to-end' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => {
                class => 'Fake::Defer::FirstUseFails::Component', dir => 'flaky',
                defer => 1, optional => 1,
            },
        })
    );
    ok $build->{success}, 'build succeeds (bare new() and probe() both pass)' or diag $build->{message};

    $Fake::Defer::FirstUseFails::Component::new_calls = 0;   # isolate open_desk()'s own effect

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds overall despite the doomed component' or diag $open->{message};
    isa_ok $open->{concierge}{flaky}, ['Concierge::Desk::DeferredComponent'],
        'DeferredComponent installed -- tier 2 probe passed, failure is not yet known';

    my $result = $open->{concierge}->flaky->greet;
    ok !$result->{success}, 'first real use resolves to a graceful failure hashref, never a live crash';
    like $result->{message}, qr/flaky.*unavailable/is, 'failure message matches UnavailableComponent format';
    is $Fake::Defer::FirstUseFails::Component::new_calls, 1,
        'the failing new($payload) was attempted exactly once';

    my $result2 = $open->{concierge}->flaky->greet;
    ok !$result2->{success}, 'second call still returns a graceful failure';
    is $Fake::Defer::FirstUseFails::Component::new_calls, 1,
        'failing new() is never retried -- permanent failure holds through the full pipeline too';
};

done_testing;
