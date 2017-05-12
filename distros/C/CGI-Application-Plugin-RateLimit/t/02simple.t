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

my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM rate_limit_hits');
is($count, 0, 'fresh rate-limit DB created');

# setup a test package which uses rate-limit
{

    package TestApp;
    use base 'CGI::Application';
    use CGI::Application::Plugin::RateLimit;

    sub setup {
        my $self = shift;
        $self->run_modes(['one', 'two', 'three', 'too_fast']);

        my $rate_limit = $self->rate_limit;

        $rate_limit->dbh($dbh);
        $rate_limit->protected_modes(one => {timeframe => '3s',
                                             max_hits  => 1
                                            },
                                     two => {timeframe => '10s',
                                             max_hits  => 2
                                            });
        $rate_limit->violation_mode('too_fast');
    }

    sub one   { "ONE" }
    sub two   { "TWO" }
    sub three { "THREE" }

    sub too_fast {
        my $self = shift;
        "TOO FAST FOR " . $self->rate_limit->violated_mode;
    }
}

# first hit should work
my $start = time;
{
    my $query = CGI->new({rm => 'one'});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/ONE/);

    # should be a row for it in the DB
    ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM rate_limit_hits');
    is($count, 1, 'first hit recorded');
}

# this one should violate
{
    my $query = CGI->new({rm => 'one'});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/TOO FAST FOR TestApp::one/);

    # should be a second row for it in the DB
    ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM rate_limit_hits');
    is($count, 2, 'second hit recorded');
}

# but a hit to run-mode two should be fine
{
    my $query = CGI->new({rm => 'two'});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/TWO/);

    # should be a row for it in the DB
    ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM rate_limit_hits');
    is($count, 3, 'third hit recorded');
}

# after 3 seconds we're clear
sleep 3;
{
    my $query = CGI->new({rm => 'one'});
    my $app = TestApp->new(QUERY => $query);
    like($app->run(), qr/ONE/);

    # should be a row for it in the DB
    ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM rate_limit_hits');
    is($count, 4, 'fourth hit recorded');
}
