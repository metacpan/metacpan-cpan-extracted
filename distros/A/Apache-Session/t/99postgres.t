
use Test::More;
use Test::Deep;

plan skip_all => "Not running RDBM tests without APACHE_SESSION_MAINTAINER=1"
  unless ($ENV{APACHE_SESSION_MAINTAINER} || $ENV{TRAVIS});
plan skip_all => "Optional modules (DBD::Pg, DBI) not installed"
  unless eval {
               require DBD::Pg;
               require DBI;
              };

plan tests => 13;

my $package = 'Apache::Session::Postgres';
use_ok $package;

my $session = {};

my ($dbname, $user, $pass) = ('test', 'postgres', '');
my $dsn = "dbi:Pg:database=$dbname";
{

    my $dbh1 = DBI->connect($dsn, $user, $pass, {RaiseError => 1, AutoCommit => 1, PrintError=>0, PrintWarn=>0,});
    foreach my $table (qw/sessions s/) {
        eval { $dbh1->do("DROP TABLE $table", {RaiseError => 0, PrintError=>0, PrintWarn=>0,});};
        $dbh1->do(<<"EOT");
 CREATE TABLE $table (
    id char(32) not null primary key,
    a_session text
 )
EOT
    }
}


tie %{$session}, $package, undef, {
    DataSource => "dbi:Pg:dbname=$dbname",
    UserName   => $user, 
    Password   => $pass,
    Commit     => 1
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
    DataSource => "dbi:Pg:dbname=$dbname",
    UserName   => $user, 
    Password   => $pass,
    Commit   => 1
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";

untie %{$session};
undef $session;
$session = {};

tie %{$session}, $package, undef, {
    DataSource => "dbi:Pg:dbname=$dbname",
    UserName   => $user, 
    Password   => $pass,
    Commit   => 1,
    TableName => 's'
};

ok tied(%{$session}), 'session tied';

ok exists($session->{_session_id}), 'session id exists';

untie %{$session};
undef $session;
$session = {};

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $user, $pass, {RaiseError => 1, AutoCommit => 0});

tie %{$session}, $package, $id, {
    Handle => $dbh,
    Commit => 0,
};

ok tied(%{$session}), 'session tied';

is $session->{_session_id}, $id, 'id retrieved matches one stored';

cmp_deeply $session->{foo}, $foo, "Foo matches";
cmp_deeply $session->{baz}, $baz, "Baz matches";

tied(%{$session})->delete;
untie %{$session};
$dbh->commit;
$dbh->disconnect;
