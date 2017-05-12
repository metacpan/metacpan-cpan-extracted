use strict;

use Test::More tests => 55;

BEGIN {
    use_ok('DBD::Mock');
}

use DBI;

{
    package Login::Test;
    
    my $MAX_LOGIN_FAILURES = 3;
    
    sub login {
        my ($dbh, $u, $p) = @_;
        # look for the right username and password
        my ($user_id) = $dbh->selectrow_array("SELECT user_id FROM users WHERE username = '$u' AND password = '$p'");
        # if we find one, then ...
        if ($user_id) {
            # log the event and return true    
            $dbh->do("INSERT INTO event_log (event) VALUES('User $user_id logged in')");
            return 'LOGIN SUCCESSFUL';
        }
        # if we don't find one then ...
        else {
            # see if the username exists ...
            my ($user_id, $login_failures) = $dbh->selectrow_array("SELECT user_id, login_failures FROM users WHERE username = '$u'");
            # if we do have a username, and the password doesnt match then ...
            if ($user_id) {
                # if we have not reached the max allowable login failures then ...
                if ($login_failures < $MAX_LOGIN_FAILURES) {
                    # update the login failures
                    $dbh->do("UPDATE users SET login_failures = (login_failures + 1) WHERE user_id = $user_id");
                    return 'BAD PASSWORD';            
                }
                # otherwise ...
                else {
                    # we must update the login failures, and lock the account
                    $dbh->do("UPDATE users SET login_failures = (login_failures + 1), locked = 1 WHERE user_id = $user_id");                                return 'USER ACCOUNT LOCKED';
                }
            }
            else {
                return 'USERNAME NOT FOUND';
            }
        }
    }
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });

    my $session = DBD::Mock::Session->new({ statement => '', results => []});
    isa_ok($session, 'DBD::Mock::Session');
    
    is($session->name(), 'Session 1', '... got the first default session name');

    $dbh->{mock_session} = $session;
    
    my $fetched_session = $dbh->{mock_session};
    is($fetched_session, $session, '... it is the same session we put in');
    
    $dbh->{mock_session} = undef;
    ok(!defined($dbh->{mock_session}), '... we no longer have a session in there');

    my $session2 = DBD::Mock::Session->new({ statement => '', results => []});
    isa_ok($session2, 'DBD::Mock::Session');
    
    is($session2->name(), 'Session 2', '... got the second default session name');
}

{
    my $successful_login = DBD::Mock::Session->new('successful_login' => ( 
        {
            statement => "SELECT user_id FROM users WHERE username = 'user' AND password = '****'",
            results   => [[ 'user_id' ], [ 1 ]]
        },
        {
            statement => "INSERT INTO event_log (event) VALUES('User 1 logged in')",
            results   => []
        }
    ));
    isa_ok($successful_login, 'DBD::Mock::Session');
    
    is($successful_login->name(), 'successful_login', '... got the right name');

    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    $dbh->{mock_session} = $successful_login;
    
    is(Login::Test::login($dbh, 'user', '****'), 'LOGIN SUCCESSFUL', '... logged in successfully');
    
    # check the reusablity
    
    # it is not reusable now
    eval {
        Login::Test::login($dbh, 'user', '****')
    };

    ok($@, '... got the exception');
    like($@, qr/Session Error\: Session states exhausted/, '... got the exception we expected');
    
    # reset the DBD::Mock::Session object
    $successful_login->reset;
    
    # and it is re-usable now
    is(Login::Test::login($dbh, 'user', '****'), 'LOGIN SUCCESSFUL', '... logged in successfully');
}

{

    my $bad_username = DBD::Mock::Session->new('bad_username' => (
        {
            statement => qr/SELECT user_id FROM users WHERE username = \'.*?\' AND password = \'.*?\'/, #'
            results   => [[ 'user_id' ], [ undef ]]
        },
        {
            statement => qr/SELECT user_id, login_failures FROM users WHERE username = \'.*?\'/, #'
            results   => [[ 'user_id', 'login_failures' ], [ undef, undef ]]
        }
    ));
    isa_ok($bad_username, 'DBD::Mock::Session');
    
    is($bad_username->name(), 'bad_username', '... got the right name');    

    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_session} = $bad_username;
    
    is(Login::Test::login($dbh, 'user', '****'), 'USERNAME NOT FOUND', '... username is not found');
}

{
    my $bad_password = DBD::Mock::Session->new('bad_password' => (
        {
            statement => sub { $_[0] eq "SELECT user_id FROM users WHERE username = 'user' AND password = '****'" },
            results   => [[ 'user_id' ], [ undef]]
        },
        {
            statement => sub { $_[0] eq "SELECT user_id, login_failures FROM users WHERE username = 'user'" },
            results   => [[ 'user_id', 'login_failures' ], [ 1, 0 ]]
        },
        {
            statement => sub { $_[0] eq "UPDATE users SET login_failures = (login_failures + 1) WHERE user_id = 1" },
            results   => []
        }
    ));
    isa_ok($bad_password, 'DBD::Mock::Session');
    
    is($bad_password->name(), 'bad_password', '... got the right name');

    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_session} = $bad_password;
    
    is(Login::Test::login($dbh, 'user', '****'), 'BAD PASSWORD', '... username is found, but the password is wrong');
}

{
    my $lock_user_account = DBD::Mock::Session->new('lock_user_account' => (
        {
            statement => "SELECT user_id FROM users WHERE username = 'user' AND password = '****'",
            results   => [[ 'user_id' ], [ undef]]
        },
        {
            statement => qr/SELECT user_id, login_failures FROM users WHERE username = \'.*?\'/, #'
            results   => [[ 'user_id', 'login_failures' ], [ 1, 4 ]]
        },
        {
            statement => sub { $_[0] eq "UPDATE users SET login_failures = (login_failures + 1), locked = 1 WHERE user_id = 1" },
            results   => []
        }
    ));
    isa_ok($lock_user_account, 'DBD::Mock::Session');
    
    is($lock_user_account->name(), 'lock_user_account', '... got the right name');

    my $dbh = DBI->connect('dbi:Mock:', '', '');
    $dbh->{mock_session} = $lock_user_account;
    
    is(Login::Test::login($dbh, 'user', '****'), 'USER ACCOUNT LOCKED', '... username is found, and the password is wrong, and the user account is now locked');
}

# now check some errors

{
    my $not_enough_statements = DBD::Mock::Session->new((
        {
            statement => "SELECT user_id FROM users WHERE username = 'user' AND password = '****'",
            results   => [[ 'user_id' ], [ undef]]
        },
        {
            statement => qr/SELECT user_id, login_failures FROM users WHERE username = \'.*?\'/, #'
            results   => [[ 'user_id', 'login_failures' ], [ 1, 4 ]]
        },
        # ... removed one statement here which DBI will be looking for
    ));
    isa_ok($not_enough_statements, 'DBD::Mock::Session');

    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    $dbh->{mock_session} = $not_enough_statements;
    
    eval {
        Login::Test::login($dbh, 'user', '****');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/Session Error\: Session states exhausted\, /, '... got the error we expected');    
    
}

{
    eval {
        DBD::Mock::Session->new()
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^You must specify at least one session state/, '... got the error we expected');
    
    eval {
        DBD::Mock::Session->new([])
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^You must specify session states as HASH refs/, '... got the error we expected');
    
    eval {
        DBD::Mock::Session->new('session')
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^You must specify at least one session state/, '... got the error we expected');    

    eval {
        DBD::Mock::Session->new('session', [])
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^You must specify session states as HASH refs/, '... got the error we expected');    

    eval {
        DBD::Mock::Session->new('session', { statement => '', results => [] }, [])
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^You must specify session states as HASH refs/, '... got the error we expected');    

}

{
    eval {
        my $session = DBD::Mock::Session->new('session' => {});
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Bad state \'0\' in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    eval {
        my $session = DBD::Mock::Session->new('session' => { statement => "" });
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Bad state \'0\' in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    eval {
        my $session = DBD::Mock::Session->new('session' => { results => [] });
       $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Bad state \'0\' in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    eval {
        my $session = DBD::Mock::Session->new('session' => {
            statement => [],
            results   => []
        });
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Bad \'statement\' value \'ARRAY\(0x[a-f0-9]+\)\' in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    my $session = DBD::Mock::Session->new('session' => 
        {
            statement => "SELECT foo FROM baz",
            results   => []
        }
    );
    isa_ok($session, 'DBD::Mock::Session');
    
    eval {
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Statement does not match current state in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    my $session = DBD::Mock::Session->new('session' => 
        {
            statement => qr/SELECT foo FROM baz/,
            results   => []
        }
    );
    isa_ok($session, 'DBD::Mock::Session');
    
    eval {
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Statement does not match current state \(with Regexp\) in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    my $session = DBD::Mock::Session->new('session' => 
        {
            statement => sub { 0 },
            results   => []
        }
    );
    isa_ok($session, 'DBD::Mock::Session');
    
    eval {
        $session->verify_statement(DBI->connect('dbi:Mock:', '', ''), 'SELECT foo FROM bar');
    };
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^Statement does not match current state \(with CODE ref\) in DBD::Mock::Session \(session\)/, '... got the error we expected');

}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    my $session = DBD::Mock::Session->new('session' => 
        {
            statement => 'Some SQL',
            results   => []
        }
    );
    isa_ok($session, 'DBD::Mock::Session');
    $dbh->{mock_session} = $session;
    eval {
        $dbh->disconnect;
    };
    
    ok(defined($@), '... got an error, as expected');
    like($@, qr/^DBH->finish called when session still has states left/, '... got the error we expected');

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}
