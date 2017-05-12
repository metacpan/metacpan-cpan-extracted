# $Id$

use strict;


use File::Spec;
use Test::More;
use CGI::Session;
use CGI::Session::Test::Default;
use Data::Dumper;

for ( "DBI", "DBD::SQLite" ) {
    eval "require $_";
    if ( $@ ) {
        plan(skip_all=>"$_ is NOT available");
        exit(0);
    }
}

my %dsn = (
    DataSource  => "dbi:SQLite:dbname=" . File::Spec->catfile('t', 'sessiondata', 'sessions.sqlt'),
    TableName   => 'sessions'
);

my $dbh = DBI->connect($dsn{DataSource}, undef, undef, {RaiseError=>1, PrintError=>1});
unless ( $dbh ) {
    plan(skip_all=>"Couldn't establish connection with the SQLite server");
    exit(0);
}

my %tables = map{ s/['"]//g; ($_, 1) } $dbh->tables();
unless ( exists $tables{ $dsn{TableName} } ) {
    unless( $dbh->do(qq|
        CREATE TABLE $dsn{TableName} (
            id CHAR(32) NOT NULL PRIMARY KEY,
            a_session TEXT NULL
        )|) ) {
        plan(skip_all=>"Couldn't create table $dsn{TableName}: " . $dbh->errstr);
        exit(0);
    }
}


my $t = CGI::Session::Test::Default->new(
    dsn => "driver:sqlite",
    args=>{Handle=> sub {$dbh}, TableName=>$dsn{TableName}});

plan tests => $t->number_of_tests + 4;

{
    # Let's start with a clean slate...
    $dbh->do("DELETE FROM sessions");

    # Build us a session object...
    my $session = CGI::Session->new('driver:sqlite', undef, \%dsn);
       $session->param('foo', 'bar');
       $session->expire('+1d');

       $session->flush();

    # Check the integrity of our saved information....
    ok($session->param('foo') eq 'bar', "Correct information has been saved in the session...");

    # Save this for later, so we can recall the info...
    my $session_id = $session->id;

    # Hey, let's see how many rows we have...
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM " . $dsn{TableName} );
       $sth->execute();

    # (Hopefully) we only have one session...
    ok($sth->fetchrow_array() == 1, "Only one copy of the session file...");

    # In the app itself, the Session is checked upon a refresh to a new screen...
    # So let's get rid of what we have, and do it again...
    undef $session;
    undef $dbh; # just being thorough.

    # Our new DB handle...
    # There's no persistance in the CGI app...
    my $dbh2 = DBI->connect($dsn{DataSource}, undef, undef, {RaiseError=>1, PrintError=>1});

    # And again..
    my $dsn2_args = {
        Handle     => $dbh2,
        TableName  => $dsn{TableName},
    };

    # New Session! Should call up the same information...
    my $session2 = CGI::Session->load('driver:sqlite', $session_id, $dsn2_args);

    # Check the integrity of our saved information....
    ok($session2->param('foo') eq 'bar', "Information is retrieved from past session alright...");

    $session2->flush;

    # How many do we have?!
    my $sth2 = $dbh2->prepare("SELECT COUNT(*) FROM " . $dsn{TableName} );
       $sth2->execute();

    # One? Two?
    ok($sth2->fetchrow_array() == 1, "Still only one copy of the session...");
}

$dbh = DBI->connect($dsn{DataSource}, undef, undef, {RaiseError=>1, PrintError=>1});

$t->run();
