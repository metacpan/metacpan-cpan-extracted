use Test::More;
use strict;
use warnings;

BEGIN {

    # skip unless DBD::SQLite is available
    if (eval { require DBD::SQLite }) {
        Test::More::plan('no_plan');
    } else {
        Test::More::plan(skip_all => 'DBD::SQLite required for tests.');
    }
}

use DBI;
use File::Temp qw(tempfile);
use CGI;

# setup test CGI environment
$ENV{REMOTE_USER}         = "test";
$ENV{CGI_APP_RETURN_ONLY} = 1;

# setup a test DB in a tempfile
my (undef, $dbfile) = tempfile("ratelimit_test_dbXXXXXX");
END { unlink $dbfile if $dbfile and -e $dbfile }

my $dbh = DBI->connect("dbi:SQLite:$dbfile", {RaiseError => 1});

# SQLite doesn't like INDEX() inside CREATE TABLE, so do them separately
$dbh->do(
    q{
  CREATE TABLE rate_limit_hits (
     user_id   VARCHAR(255)      NOT NULL,
     action    VARCHAR(255)      NOT NULL,
     timestamp UNSIGNED INTEGER  NOT NULL
  )
});
$dbh->do(
    q{
  CREATE INDEX rate_limit_hits_index 
  ON rate_limit_hits (user_id, action, timestamp)
});

# setup a test package which uses rate-limit
{

    package TestApp;
    use base 'CGI::Application';
    use CGI::Application::Plugin::RateLimit;

    sub setup {
        my $self = shift;
        $self->run_modes(['one', 'two', 'three', 'too_fast', 'login']);

        my $rate_limit = $self->rate_limit;

        $rate_limit->dbh($dbh);
        $rate_limit->protected_modes(one => {timeframe => '3s',
                                             max_hits  => 1
                                            },
                                     two => {timeframe => '10s',
                                             max_hits  => 2
                                            });
        $rate_limit->protected_actions(failed_login => { timeframe => '3s',
                                                         max_hits  => 3 });
        $rate_limit->violation_mode('too_fast');
    }

    sub one   { 
        my $self = shift;
        $self->rate_limit->revoke_hit if $self->query->param('revoke_me');
        return "ONE";
    }
    sub two   { 
        "TWO" 
    }
    sub login {
        my $self = shift;
        my $rate_limit = $self->rate_limit;
        if ($self->query->param('failed')) {
            $rate_limit->record_hit(action => "failed_login");
            return $self->too_fast
              if $rate_limit->check_violation(action => "failed_login");
        }
        return "LOGIN";
    }
    sub three { "THREE" }

    sub too_fast {
        my $self = shift;
        "TOO FAST FOR " . ($self->rate_limit->violated_mode || $self->rate_limit->violated_action);
    }
}

# try revoking a hit
my $start = time;
{
    my $query = CGI->new({rm => 'one', revoke_me => 1});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/ONE/);

    $query->param(revoke_me => 0);
    $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/ONE/);

    $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/TOO FAST/);
}

# try a protected action, across a few users
for my $user (qw(eenie meenie moe)) {
    $ENV{REMOTE_USER} = $user;
    for (1 .. 3) {
        my $query = CGI->new({rm => 'login', failed => 1});
        my $app = TestApp->new(QUERY => $query);
        like($app->run(), qr/LOGIN/);
    }

    my $query = CGI->new({rm => 'login', failed => 1});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/TOO FAST FOR failed_login/);
}
