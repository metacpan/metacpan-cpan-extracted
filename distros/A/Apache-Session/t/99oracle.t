use Test::More;
use Test::Deep;

plan skip_all => "Not running RDBM tests without APACHE_SESSION_MAINTAINER=1"
  unless $ENV{APACHE_SESSION_MAINTAINER};
plan skip_all => "Optional modules (DBD::Oracle, DBI) not installed"
  unless eval {
               require DBD::Oracle;
               require DBI;
              };

plan tests => 13;

my $package = 'Apache::Session::Oracle';
use_ok $package;

my $session = {};
#$ENV{ORACLE_SID}='';$ENV{AS_ORACLE_USER}='test/test';
my $dsn = "dbi:Oracle:$ENV{ORACLE_SID}";
my $user = $ENV{AS_ORACLE_USER};
my $pass = $ENV{AS_ORACLE_PASS};
{
    my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1, AutoCommit => 1, PrintError=>0, });
    foreach my $table (qw/sessions_perl/) {
        eval { $dbh->do("DROP TABLE $table", {RaiseError => 0, PrintError=>0, });};
        $dbh->do(<<"EOT");
 CREATE TABLE $table (
    id varchar2(32) not null primary key,
    a_session long
 )
EOT
    }
}

tie %{$session}, $package, undef, {
    DataSource => $dsn,
    UserName => $user,
    Password => $pass,
    Commit   => 1,
    TableName => 'sessions_perl',
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';

my $id = $session->{_session_id};

my $foo = $session->{foo} = 'bar';
my $baz = $session->{baz} = ['tom', 'dick', 'harry'];

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id, {
    DataSource => $dsn, 
    UserName => $user, 
    Password => $pass,
    Commit   => 1,
    TableName => 'sessions_perl',
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";

$session->{long} = 'A'x(10*2**10);

untie %{$session};
undef $session;
$session = {};

my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1, AutoCommit => 0});

tie %{$session}, $package, $id, {
    Handle      => $dbh,
    Commit      => 0,
    LongReadLen => 20*2**10,
    TableName => 'sessions_perl',
};

ok tied(%{$session}), 'session tied';

is $session->{long}, 'A'x(10*2**10), 'long read worked';

delete $session->{long};

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, $id, {
    Handle => $dbh,
    Commit => 0,
    TableName => 'sessions_perl',
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";

tied(%{$session})->delete;
untie %{$session};

$dbh->commit;
$dbh->disconnect;
