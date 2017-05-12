eval {
	require Test::More;
};
if ($@) {
	warn "\nTest::More is not available, skipping...\n";
	print "1..1\nok\n";
	exit;
	
}

require Test::More;
import Test::More tests => 7;

require_ok (DBIx::HA);

my $dbname='NONE'; # for checking if callbackfunction was called
my $connect_attributes = {
         syb_flush_finish => 1,
         AutoCommit => 1,
         ChopBlanks => 1,
         PrintError => 0,
         RaiseError => 0,
         RootClass  => 'DBIx::HA'
         };

$DATABASE::conf{'test'} = {
    max_retries => 2,
    db_stack => [
        [ 'dbi:NullP:server=prod1;database=test', 'user1', 'password1', $connect_attributes ],
        [ 'dbi:NullP:server=prod2;database=test', 'user2', 'password2', $connect_attributes ],
        [ 'dbi:NullP:server=prod3;database=test', 'user3', 'password3', $connect_attributes ],
        ],
    pingtimeout     => -1,
    failoverlevel   => 'process',
    connecttimeout  => 1,
    executetimeout  => 8,
    callback_function => \&MyCallbackFunction,
    };

sub MyCallbackFunction {
	my $dbh = shift;
	$dbname = shift;
	1;
}

is (DBIx::HA->initialize(), '', 'initialize()');
my $dbh = DBIx::HA->connect('test');
is (ref($dbh), 'DBIx::HA::db', 'connect()');
    
my $sth = $dbh->prepare("select 1");
is (ref($sth), 'DBIx::HA::st', 'prepare()');

is ($sth->execute, 1, 'execute()');
is ($DATABASE::conf{'test'}->{'active_db'}, $DATABASE::conf{'test'}->{'db_stack'}->[0], 'primary db active, no failover');
is ($dbname, 'NONE', 'callback function was not called');

$sth->fetchall_arrayref;
$dbh->disconnect;

__END__
