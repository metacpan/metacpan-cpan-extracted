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
# Fake components satisfying the duck-typed Concierge::Desk::Component
# contract, used to exercise the generic components-loading mechanism in
# isolation, without depending on a real installed component such as
# Concierge::Organizations.
# ==============================================================================

package Fake::Good::Component {
    sub new ($class, $payload = undef) {
        return bless { payload => $payload }, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', greeting => 'hello', dir => $config->{dir} };
    }
    sub greet ($self) {
        return { success => 1, message => $self->{payload}{greeting} };
    }
}

package Fake::BuildFails::Component {
    # setup() always fails -- build_desk() must fail the whole build.
    sub new ($class, $payload = undef) { return bless {}, $class; }
    sub setup ($self, $config) {
        return { success => 0, message => "fake setup deliberately fails for '$config->{name}'" };
    }
}

package Fake::RuntimeFails::Component {
    # setup() succeeds at build time; new() dies at open_desk() runtime
    # (i.e. when called with a defined payload -- the bare build-time
    # new() call must still succeed for setup() to run at all).
    sub new ($class, $payload = undef) {
        die "Fake::RuntimeFails::Component deliberately dies in new()\n" if defined $payload;
        return bless {}, $class;
    }
    sub setup ($self, $config) {
        return { success => 1, message => 'fake setup ok', dir => $config->{dir} };
    }
}

# Pretend these fake packages are already-loaded modules at
# Fake/Good/Component.pm etc, so the generic loop's require() finds them
# already satisfied in %INC instead of trying to load a file from disk.
$INC{'Fake/Good/Component.pm'}         = 1;
$INC{'Fake/BuildFails/Component.pm'}   = 1;
$INC{'Fake/RuntimeFails/Component.pm'} = 1;

# ==============================================================================
# build_desk() / open_desk() -- the generic components mechanism
# ==============================================================================

sub base_desk_config ($desk_dir, $components) {
    return {
        base_dir   => $desk_dir,
        auth       => { backend => 'pwd' },
        sessions   => { backend => 'database' },
        users      => { backend => 'database', include_standard_fields => [] },
        components => $components,
    };
}

subtest 'required component loads successfully' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            fakegood => { class => 'Fake::Good::Component', dir => 'fakegood' },
        })
    );
    ok $build->{success}, 'build_desk succeeds with a components block';
    is $build->{config}{components}{fakegood}{class}, 'Fake::Good::Component', 'class recorded';
    is $build->{config}{components}{fakegood}{optional}, 0, 'optional defaults to false';
    ok $build->{config}{components}{fakegood}{payload}{success}, 'setup() payload recorded';

    # Confirm the resolved payload was persisted verbatim into
    # concierge.conf at build time (not recomputed at open_desk() time).
    my $conf_file = File::Spec->catfile($desk_dir, 'concierge.conf');
    open my $fh, '<', $conf_file or die "Cannot read $conf_file: $!";
    local $/;
    my $saved = decode_json(<$fh>);
    close $fh;
    is $saved->{components}{fakegood}{class}, 'Fake::Good::Component',
        'components.<name>.class persisted to concierge.conf';
    is $saved->{components}{fakegood}{payload}{greeting}, 'hello',
        'components.<name>.payload persisted verbatim from setup()';

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk succeeds';
    isa_ok $open->{concierge}{fakegood}, ['Fake::Good::Component'], 'component instantiated';
    is $open->{concierge}->fakegood->greet, { success => 1, message => 'hello' },
        'generic accessor installed and component method callable';
};

subtest 'setup() failure always fails the whole build, even if optional' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            broken => { class => 'Fake::BuildFails::Component', dir => 'broken', optional => 1 },
        })
    );
    ok !$build->{success}, 'build fails when a component setup() fails';
    like $build->{message}, qr/broken/, 'error message names the failing component';
};

subtest 'required component failing at open_desk() time croaks' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => { class => 'Fake::RuntimeFails::Component', dir => 'flaky' },
        })
    );
    ok $build->{success}, 'build succeeds (setup() succeeds at build time)';

    like dies { Concierge->open_desk($desk_dir) },
        qr/Failed to load required component 'flaky'/,
        'open_desk croaks for a required component whose new() fails';
};

subtest 'optional component failing at open_desk() time substitutes UnavailableComponent' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk(
        base_desk_config($desk_dir, {
            flaky => { class => 'Fake::RuntimeFails::Component', dir => 'flaky', optional => 1 },
        })
    );
    ok $build->{success}, 'build succeeds';
    is $build->{config}{components}{flaky}{optional}, 1, 'optional flag recorded as true';

    my $open = Concierge->open_desk($desk_dir);
    ok $open->{success}, 'open_desk still succeeds overall';
    isa_ok $open->{concierge}{flaky}, ['Concierge::Desk::UnavailableComponent'],
        'failed optional component substituted with UnavailableComponent';

    my $result = $open->{concierge}->flaky->whatever_method_name('arg');
    ok !$result->{success}, 'calling any method on the stand-in returns a failure hashref';
    like $result->{message}, qr/unavailable/i, 'message explains the component is unavailable';
};

# ==============================================================================
# Concierge::Desk::UnavailableComponent -- direct tests
# ==============================================================================

subtest 'Concierge::Desk::UnavailableComponent' => sub {
    my $comp = Concierge::Desk::UnavailableComponent->new(
        name => 'widgets', reason => "connection refused",
    );
    isa_ok $comp, ['Concierge::Desk::UnavailableComponent'];

    my $r1 = $comp->some_arbitrary_method(1, 2, 3);
    ok !$r1->{success}, 'AUTOLOAD returns a failure hashref for any called method';
    like $r1->{message}, qr/widgets.*unavailable.*connection refused/s,
        'message includes the component name and the failure reason';

    my $r2 = $comp->another_method;
    ok !$r2->{success}, 'AUTOLOAD works for a second, different method name';

    ok !$comp->can('some_arbitrary_method'),
        'can() does NOT report true for AUTOLOAD-handled methods (documented probe caveat)';

    ok lives { undef $comp },
        'own DESTROY runs cleanly at teardown instead of falling through to AUTOLOAD';
};

done_testing;
