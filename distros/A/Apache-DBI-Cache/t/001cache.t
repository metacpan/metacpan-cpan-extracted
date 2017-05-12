use strict;
use Test::More tests => 16;
use Test::Deep;

sub n($) {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

BEGIN{$ENV{APACHE_DBI_CACHE_ENVPATH}="t/dbenv";}

BEGIN { use_ok('Apache::DBI::Cache') };

$Apache::DBI::Cache::DELIMITER='^';

my ($dsn1, $dsn2, $statkey1, $statkey2);
if( eval {require DBD::SQLite;} ) {
  print "# using DBD::SQLite\n";
  $dsn1='dbi:SQLite:dbname=x.sqlite';
  $dsn2='dbi:SQLite:dbname=y.sqlite';
  $statkey1='SQLite^dbname=x.sqlite^';
  $statkey2='SQLite^dbname=y.sqlite^';
} else {
  print "# using DBD::DBM\n";
  $dsn1='dbi:DBM:f_dir=tmp1';
  $statkey1='DBM^f_dir=tmp1^';
  $dsn2='dbi:DBM:f_dir=tmp2';
  $statkey2='DBM^f_dir=tmp2^';
}

Apache::DBI::Cache::connect_on_init($dsn1);
Apache::DBI::Cache->connect_on_init($dsn2);

Apache::DBI::Cache::init;

SKIP: {
  skip 'BerkeleyDB not installed', 2 unless eval {require BerkeleyDB};
  ok(-d "t/dbenv", n 'BerkeleyDB environment initialized');
  ok(tied %{Apache::DBI::Cache::statistics()}, n 'tied %STAT');
}

my $stat=Apache::DBI::Cache::statistics;

cmp_deeply( $stat->{$statkey1}, [1,1,1,0,0],
	    n 'connect_on_init1' );

cmp_deeply( $stat->{$statkey2}, [1,1,1,0,0],
	    n 'connect_on_init2' );

my $html=join '', @{Apache::DBI::Cache::statistics_as_html()};
if( tied %{$stat} ) {
  cmp_deeply( $html, re('<h1>DBI Handle Statistics for this machine</h1>'),
	      n 'html statistics header' );
} else {
  cmp_deeply( $html, re('<h1>DBI Handle Statistics for process \d+</h1>'),
	      n 'html statistics header' );
}

my @l1=split /\^/, $statkey1;
my @l2=split /\^/, $statkey2;
cmp_deeply( $html,
	    all( re("<tr><td>\Q$l1[0]\E</td><td>\Q$l1[1]\E</td><td>&nbsp;</td><td>1</td><td>1</td><td>1</td><td>0</td><td>0</td></tr>"),
		 re("<tr><td>\Q$l2[0]\E</td><td>\Q$l2[1]\E</td><td>&nbsp;</td><td>1</td><td>1</td><td>1</td><td>0</td><td>0</td></tr>") ),
	    n 'html statistics elements' );

my ($dbh1, $dbh2);
$dbh1=DBI->connect($dsn1);
$dbh1="$dbh1";
$dbh2=DBI->connect($dsn1);
$dbh2="$dbh2";
ok $dbh1 eq $dbh2, n "got identical handles";

$dbh1=DBI->connect($dsn1);
$dbh2=DBI->connect($dsn1);

cmp_deeply( $stat->{$statkey1}, [2,0,5,0,0],
	    n 'statistics after usage1' );

$dbh1="$dbh1";
$dbh2="$dbh2";
ok $dbh1 ne $dbh2, n "got different handles";

cmp_deeply( $stat->{$statkey1}, [2,2,5,0,0],
	    n 'statistics after usage2' );

Apache::DBI::Cache::finish;
ok(!tied %{Apache::DBI::Cache::statistics()}, n '%STAT is not tied after finish()');

SKIP: {
  skip 'BerkeleyDB not installed', 2 unless eval {require BerkeleyDB};

  my $envpath=$ENV{APACHE_DBI_CACHE_ENVPATH};
  my $env=BerkeleyDB::Env->new
    ( -Home=>$envpath,
      -Cachesize=>$ENV{APACHE_DBI_CACHE_CACHESIZE}||20*1024,
      -ErrFile=>\*STDERR,
      -ErrPrefix=>__PACKAGE__.' BerkeleyDB',
      -Flags=>(&BerkeleyDB::DB_CREATE|
	       &BerkeleyDB::DB_INIT_CDB|
	       &BerkeleyDB::DB_INIT_MPOOL),
    );
  die "ERROR: Cannot create BerkeleyDB environment ($envpath): $BerkeleyDB::Error\n"
    unless( $env );

  my $STATdb=tie( my %STAT, 'BerkeleyDB::Btree',
		  -Filename=>'handles.db',
		  -Env=>$env,
		  -Flags=>&BerkeleyDB::DB_CREATE,
	     );
  $STATdb->filter_store_value( sub {$_=join ':', @$_} );
  $STATdb->filter_fetch_value( sub {$_=[split ':', $_]} );

  ok keys %STAT, n 'statistics not empty after finish()';
  cmp_deeply( [values %STAT], array_each([0,0,ignore(),ignore(),ignore()]),
	      n 'statistics reset after finish()' );
}

{
  my $x=1;
  my $y=bless( \ (my $yy=1), 'klaus' );
  my $z=1;
  Apache::DBI::Cache::undef_at_request_cleanup( \$x, \$y );
  Apache::DBI::Cache::undef_at_request_cleanup( \$z );
  Apache::DBI::Cache::request_cleanup;
  cmp_deeply [$x, $y, $z], [undef, undef, undef], n 'undef_at_request_cleanup';

  $x=1;
  $z=1;
  Apache::DBI::Cache::undef_at_request_cleanup( \$z );
  Apache::DBI::Cache::request_cleanup;
  cmp_deeply [$x, $z], [1, undef], n 'undef_at_request_cleanup 2';
}

# Local Variables:
# mode: perl
# End:
