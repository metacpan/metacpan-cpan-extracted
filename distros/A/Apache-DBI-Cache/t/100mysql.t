use strict;
use Test::More;
use Test::Deep;

sub n($) {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

# APACHE_DBI_CACHE_MYSQL1 and APACHE_DBI_CACHE_MYSQL2 should point to
# 2 different databases on the same host and port.

BEGIN {
  if( exists $ENV{MYSQL1} and length $ENV{MYSQL1} and
      exists $ENV{MYSQL2} and length $ENV{MYSQL2} ) {
    $ENV{MYSQL_HOST}='localhost' unless exists $ENV{MYSQL_HOST};
    $ENV{MYSQL_USER}='' unless exists $ENV{MYSQL_USER};
    $ENV{MYSQL_PASSWD}='' unless exists $ENV{MYSQL_PASSWD};
    plan tests=>8;
  } else {
    plan skip_all => 'no database given, see README';
  }
}

BEGIN{$ENV{APACHE_DBI_CACHE_ENVPATH}="t/dbenv";}

use Apache::DBI::Cache;
BEGIN { use_ok('Apache::DBI::Cache::mysql') };

my ($db1, $db2, $host, $user, $pw)=@ENV{qw/MYSQL1
					   MYSQL2
					   MYSQL_HOST
					   MYSQL_USER
					   MYSQL_PASSWD/};
$host='localhost' unless( length $host );

$Apache::DBI::Cache::DELIMITER='^';

my $statkey="mysql^host=$host;port=3306^$user";

sub current_db {
  my $dbh=shift;

  my $db;
  my $id=$dbh->{mysql_thread_id};
  my $st=$dbh->prepare('show processlist');
  $st->execute;
  while( my $l=$st->fetchrow_arrayref ) {
    $db=$l->[3] if( $l->[0]==$id );
  }
  return $db;
}

Apache::DBI::Cache::connect_on_init
  ("dbi:mysql:dbname=$db1;host=$host;port=3306", "$user", "$pw" );

Apache::DBI::Cache::connect_on_init
  ("dbi:mysql:$db2:$host", "$user", "$pw" );

Apache::DBI::Cache::init;

my $stat=Apache::DBI::Cache::statistics;

cmp_deeply( $stat->{$statkey}, [2,2,2,0,0],
	    n 'connect_on_init' );

my $dbh=DBI->connect("dbi:mysql:$db2:$host:3306", "$user", "$pw" );

cmp_deeply( ref $dbh, 'Apache::DBI::Cache::db',
	    n 'is a Apache::DBI::Cache::db' );

ok( $dbh->{mysql_auto_reconnect}==0, n 'mysql_auto_reconnect==0' );

cmp_deeply( $stat->{$statkey}, [2,1,3,0,0],
	    n 'usage count' );

my ($dba, $dbb);
cmp_deeply( current_db($dba=DBI->connect("dbi:mysql:host=$host;database=$db1", "$user", "$pw" )),
	    $db1, n 'DB1' );
$dba="$dba";

cmp_deeply( current_db($dbb=DBI->connect("dbi:mysql:port=3306;db=$db2;host=$host", "$user", "$pw" )),
	    $db2, n 'DB2' );
$dbb="$dbb";

cmp_deeply( $dba, $dbb, n 'got the same handle for different databases' );

undef $dbh;

$SIG{__WARN__}=sub {
  print STDERR "@_";
  fail n "finish() is optional";
};

# finish is now called automagically
#Apache::DBI::Cache::finish;

# Local Variables:
# mode: perl
# End:
