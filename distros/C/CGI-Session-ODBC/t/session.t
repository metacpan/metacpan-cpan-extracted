#!perl

use strict;
use warnings;
use Test::More tests => 36;

BEGIN
{
    # CGI::Session load ok?
    use_ok("CGI::Session");
}

my ($dsn, $user, $pass, $table);
BEGIN
{
    # What table should we use for session tests?
    $table = "CSO_session_test";

    # Drop out if we don't have database connectivity
    eval "require DBI";
    die "DBI required to test $0" if $@;

    eval "require DBD::ODBC";
    die "DBD::ODBC required to test $0" if $@;

    # Get environment vars needed for a database connection
    my $_dsn  = $ENV{DBI_DSN}  || "";
    my $_user = $ENV{DBI_USER} || "";
    my $_pass = $ENV{DBI_PASS} || "";

    # Detaint
    $dsn  = $1 if $_dsn =~ /^([a-zA-Z\d_: -]+)$/;
    $user = $1 if $_user =~ /^([a-zA-Z\d_: -\.]+)$/;
    $pass = $_pass; # Will this be too unsafe?

    # Make sure we have DBI:ODBC: before the DSN name
    $dsn = "DBI:ODBC:$dsn" if $dsn !~ /^DBI:ODBC:/;

    # Make sure we have a blank password (at minimum)
    $pass = "" if not defined $pass;

    # Make sure the user has set the propert ENV vars
    die "Environment variable DBI_DSN required to test $0"  unless defined $dsn;
    die "Environment variable DBI_USER required to test $0" unless defined $user;
};

SESSION_SETUP:
{
    # Create a session table in the specified database
    my $dbh = DBI->connect($dsn, $user, $pass) or die "Cannot connect to $dsn database: ", DBI->errstr;
    my $sql = qq{
        CREATE TABLE $table
        (
            id        CHAR(32) NOT NULL,
            a_session TEXT     NOT NULL
        );
    };

    $dbh->do($sql) or die "Cannot create session table: ", $dbh->errstr;
    $dbh->disconnect;
}

SESSION_USAGE:
{
    # Create our session
    my %options = (
        DataSource => $dsn,
        User       => $user,
        Password   => $pass,
        TableName  => $table,
    );

    my $s_create = new CGI::Session("driver:ODBC", undef, \%options );

    # Valid session?
    isa_ok($s_create, "CGI::Session");

    # Valid Session ID?
    ok($s_create->id, "Got new session ID");
    like($s_create->id, qr/^[\dA-F]{32}$/i, "Valid MD5 value for session ID");

    # Can we store and retrieve session data ok?
    my $author = "Jason A. Crome";
    my $module = "CGI::Session::ODBC";
    my $email  = 'cromedome@cpan.org';

    ok($s_create->param(author => $author,
                        module => $module,
                        email  => $email), "Store session parameters");

    is($s_create->param("author"), $author, "Author param matches"  );
    is($s_create->param("module"), $module, "Module name matches"   );
    is($s_create->param("email"),  $email,  "E-Mail address matches");

    # Fetch information about the session
    ok($s_create->atime, "View session's last access time"   );
    ok($s_create->ctime, "View session's creation time"      );

    # Check session expiration
    ok(!$s_create->expire(),      "Session not expired"             );
    ok($s_create->expire("+10m"), "Session expiration time extended");
    ok($s_create->expire(),       "Check expiration time"           );

    # Check parameter expiration
    ok($s_create->param("ExpTest",    "Expiration Test"), "Set parameter to expire"      );
    ok($s_create->expire("ExpTest",   1                ), "Set parameter expiration time");
    diag("Waiting for session to expire");
    sleep 2;
    is($s_create->param("email"),     $email,             "Parameter not expired");
    isnt($s_create->param("ExpTest"), "Expiration Test",  "Parameter expired");

    # Close the original session.  Save off the original ID.
    my $sid = $s_create->id();
    ok($s_create->close(), "Closed original session");

    # Create a new session
    my $s_verify = new CGI::Session("driver:ODBC", $sid, \%options);

    # Make sure session is valid.
    isa_ok($s_verify, "CGI::Session");

    # Make sure it's the existing session
    is($s_verify->id(), $sid, "Reopen of existing session");

    # Make sure parameters are the same as before
    is($s_verify->param("author"), $author, "Author param matches"  );
    is($s_verify->param("module"), $module, "Module name matches"   );
    is($s_verify->param("email"),  $email,  "E-Mail address matches");

    # Test integration with CGI objects
    SKIP:
    {
        eval { require CGI };
        skip "CGI not installed", 7 if $@;

        # Create a new CGI object
        my $request = new CGI;
        isa_ok($request, "CGI");

        # Fill our CGI object with session parameters
        $s_verify->load_param($request);

        # Check parameters
        is($s_verify->param("author"), $request->param("author"), "Author CGI param matches session"  );
        is($s_verify->param("module"), $request->param("module"), "Module CGI name matches session"   );
        is($s_verify->param("email"),  $request->param("email"),  "E-Mail CGI address matches session");

        # Add a new parameter
        ok($request->param("AuthorEmail", "$author <$email>"), "Added new CGI parameter");

        # Save CGI parameters to our session
        ok($s_verify->save_param($request), "Populate session with CGI data");

        # Check for existence of new parameter
        is($s_verify->param("AuthorEmail"), $request->param("AuthorEmail"), "Session matches CGI parameters");
    }

    # Test parameter clearing
    ok($s_verify->clear(["author",   "module"]), "Cleared author and module parameters");
    isnt($s_verify->param("author"), $author,    "Verify that author parameter cleared");
    isnt($s_verify->param("module"), $module,    "Verify that module parameter cleared");
    ok($s_verify->clear,                         "Cleared remaining parameters"        );
    is($s_verify->param("email"),    undef,      "Verify that e-mail parameter cleared");

    # Clean up
    ok($s_verify->delete(), "Deleted session");
}

SESSION_CLEANUP:
{
    my $dbh = DBI->connect($dsn, $user, $pass) or die "Cannot connect to $dsn database: ", DBI->errstr;
    $dbh->do("DROP TABLE $table") or die "Cannot delete session table: ", $dbh->errstr;
    $dbh->disconnect();
}

