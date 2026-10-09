#!perl
use strict;
use warnings;

# Three Dancer2 applications in one file, on purpose: the whole point is to show
# the same engine installed three ways, and the trap only appears in the
# comparison.
## no critic (Modules::ProhibitMultiplePackages)

# The recipe in "CONNECTIONS" in the POD, through a real Dancer2 application and
# a real request cycle.
#
# It is here because that recipe is not obvious and the obvious alternative is
# DANGEROUS. `dbh` can be a coderef, a coderef cannot be written in YAML, and so
# the engine has to be built in Perl and installed -- at which point the natural
# thing to write, `set session => $engine`, silently does nothing if the session
# engine already exists and leaves the application on Dancer2::Session::Simple:
# sessions in memory, unencrypted, not shared between workers.
#
# The second subtest asserts that Dancer2 behaviour deliberately. IF IT STARTS
# FAILING, Dancer2 has changed and the POD section "Why not set session =>
# $engine" needs rewriting -- that is the point of having it.

use Test2::V1 qw( -utf8 -x ), -include => [ [ 'Test2::Tools::Subtest', 'subtest_streamed' ] ];

use FindBin qw( $Bin );    ## no critic (Community::DiscouragedModules) -- how a test finds t/lib; the warning is for applications
use lib "$Bin/lib";
use SessionPgTest::PgDB  ();
use Dancer2::Session::Pg ();
use Plack::Test;
use HTTP::Request::Common qw( GET );

my ($dbh) = SessionPgTest::PgDB::provision() or T2->skip_all($SessionPgTest::PgDB::REASON);

$dbh->do(<<'SQL');
CREATE TABLE sessions (
    id           text        PRIMARY KEY,
    principal_id text,
    session_data bytea       NOT NULL,
    created      timestamptz NOT NULL DEFAULT now(),
    updated      timestamptz NOT NULL DEFAULT now(),
    expires      timestamptz
)
SQL

my $KEY32 = 'a' x 64;

sub engine {
    return Dancer2::Session::Pg->new(

        # The coderef form, which is the whole reason this cannot live in YAML.
        dbh              => sub { return $dbh },
        dbtable          => 'sessions',
        encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
        principal_key    => 'principal',
        session_duration => 900,
    );
}

# --- the documented way: app->set_session_engine -----------------------------
{

    package TestApp::Good;
    use Dancer2;

    app->set_session_engine( main::engine() );

    get '/sign-in' => sub { session principal => 'PRL-APP'; return 'in' };
    get '/whoami'  => sub { return session('principal') || 'nobody' };
}

T2->subtest_streamed(
    q{the documented way: app->set_session_engine} => sub {
        my $test = Plack::Test->create( TestApp::Good->to_app );

        T2->is( ref TestApp::Good::app()->session_engine, 'Dancer2::Session::Pg', 'set_session_engine installs the engine' );

        my $signed = $test->request( GET '/sign-in' );
        T2->is( $signed->code, 200, 'a request that writes a session succeeds' );

        my $cookie = $signed->header('Set-Cookie') || q{};
        $cookie =~ s/;.*//msx;
        T2->ok( length $cookie, 'and sets a session cookie' );

        my $back = $test->request( GET '/whoami', Cookie => $cookie );
        T2->is( $back->content, 'PRL-APP', 'a later request reads the session back out of Pg' );

        my ( $rows, $principal ) = $dbh->selectrow_array('SELECT count(*), max(principal_id) FROM sessions');
        T2->is( $rows,      1,         'exactly one row was written' );
        T2->is( $principal, 'PRL-APP', 'with the principal in its clear column' );

        my ($blob) = $dbh->selectrow_array('SELECT session_data FROM sessions');
        T2->is( ( unpack 'C3', $blob )[0], 1, 'and an encrypted payload in the documented format' );
        T2->ok( index( $blob, 'PRL-APP' ) < 0, 'whose plaintext is not in the bytes' );
    }
);

# --- the trap: "set session => $engine" after the engine exists --------------
{

    package TestApp::Trap;
    use Dancer2;

    # Anything at all that touches the session engine first: another `set
    # session`, a `session:` key in config.yml, a plugin, or this.
    app->session_engine;

    set session => main::engine();
}

# And it does work when nothing has built one yet -- so the POD can say "only
# if it has not already run" rather than "never works".
{

    package TestApp::Lucky;
    use Dancer2;
    set session => main::engine();
}

T2->subtest_streamed(
    q{the trap: setting session to an object depends on ordering} => sub {
        T2->is( ref TestApp::Trap::app()->session_engine,
            'Dancer2::Session::Simple', 'setting session to an object is SILENTLY IGNORED once an engine exists' );

        T2->is( ref TestApp::Lucky::app()->session_engine,
            'Dancer2::Session::Pg', 'while the same line works when it happens to run first' );
    }
);

T2->done_testing;
