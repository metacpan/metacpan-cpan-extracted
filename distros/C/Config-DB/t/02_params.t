use Test::More tests => 6;

my $dbh = DBI->connect( 'DBI:DBM:', undef, undef );

eval { $dbh->do("DROP TABLE notable"); };

BEGIN { use_ok 'Config::DB' }
require_ok('Config::DB');

my $cfg = Config::DB->new(
    connect => ['DBI:NotInstalled'],
    tables  => { dummy => 'dummy' }
);

eval { $cfg->read };
my $msg = $@;
$msg =~ s/\n//g;
like(
    $msg,
qr{^Can't connect to data source 'DBI:NotInstalled'.*Config::DB::read: can't connect at t/02_params.t line \d+$},
    'connection error'
);

$cfg = Config::DB->new(
    connect => [ 'DBI:DBM:', undef, undef, {} ],
    tables => { notable => 'nofield' }
);

eval { $cfg->read };
$msg = $@;
$msg =~ s/\n//g;
like(
    $msg,
qr{^DBD::DBM::db selectall_hashref failed.*Config::DB::read: reading 'notable' table at t/02_params.t line \d+$},
    'missing table'
);

$dbh->do("CREATE TABLE notable (dummy INTEGER, a INTEGER)");

eval { $cfg->read };
$msg = $@;
$msg =~ s/\n//g;
like(
    $msg,
qr{^DBD::DBM::db selectall_hashref failed.*Config::DB::read: reading 'notable' table at t/02_params.t line \d+$},
    'missing field'
);

$dbh->do("DROP TABLE notable");
$dbh->do("CREATE TABLE notable (nofield INTEGER, a INTEGER)");

eval { $cfg->read };
is( $@, '', 'ok call' );
