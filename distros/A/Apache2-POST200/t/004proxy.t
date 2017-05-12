use strict;
use warnings FATAL => 'all';

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw{GET POST};
use Apache2::Const -compile=>qw{:options};
use DBI;
use DBD::SQLite;

plan tests=>20, have_module qw(mod_rewrite mod_proxy mod_proxy_http);

my $serverroot=Apache::Test::vars->{serverroot};

my ($db,$user,$pw)=@ENV{qw/DB USER PW/};
unless( defined $db and length $db ) {
  ($db,$user,$pw)=("dbi:SQLite:dbname=$serverroot/test.sqlite", '', '');
}
t_debug "Using DB=$db USER=$user";
my $dbh;
sub prepare_db {
  $dbh=DBI->connect( $db, $user, $pw,
		     {AutoCommit=>1, PrintError=>0, RaiseError=>1} )
    or die "ERROR: Cannot create database $serverroot/test.sqlite: $DBI::errstr\n";

  eval {
    $dbh->do( <<'SQL' );
CREATE TABLE p200 ( session text, data blob )
SQL
  } or $dbh->do( <<'SQL' );
DELETE FROM p200
SQL
}

prepare_db;

sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

######################################################################
## the real tests begin here                                        ##
######################################################################

Apache::TestRequest::module('Backend');
t_debug("connecting to ".Apache::TestRequest::hostport);

t_debug "POST ".Apache::TestRequest::module2url('Backend', {path=>'/mp/method'});
my $resp=POST '/mp/method';
ok t_cmp $resp->code, 200, n 'Backend return 200 on POST';

Apache::TestRequest::module('default');
t_debug("connecting to ".(my $hostport=Apache::TestRequest::hostport));

t_debug "POST ".Apache::TestRequest::module2url('default', {path=>'/proxy/mp/method'});
$resp=GET '/proxy/mp/method';
ok t_cmp $resp->code, 200, n 'GET => 200';
ok t_cmp $resp->content, 'GET:', n 'GET content=GET';

$resp=POST '/proxy/mp/method';
my $loc=$resp->header('Location');
ok t_cmp $resp->code, 302, n 'POST => 302';
ok t_cmp $loc, qr!\Q$hostport\E/proxy/mp/method\?-redirect-[A-Za-z0-9@=-]{32}$!, n 'Location';

my $header=$dbh->selectall_arrayref
  ('SELECT data FROM p200 WHERE session=?', {},
   substr( $loc, -32 ).':00000001')->[0]->[0];
ok t_cmp $header, qr/^X-My-Header: hallo opi\r?$/m, n 'checking my header';
ok t_cmp $header, qr/^X-My-Error: error\r?$/m, n 'checking my error header';

ok t_cmp $dbh->selectall_arrayref
           ('SELECT data FROM p200 WHERE session=?', {},
	    substr( $loc, -32 ).':00000003')->[0]->[0],
         "text/slain", n 'checking content-type';

ok t_cmp $dbh->selectall_arrayref
           ('SELECT data FROM p200 WHERE session=?', {},
	    substr( $loc, -32 ).':00000004')->[0]->[0],
         'POST:', n 'POST result in DB';

$resp=GET $loc;
ok t_cmp $resp->content, 'POST:', n 'POST content=POST';
ok t_cmp $resp->header('X-My-Header'), 'hallo opi', n 'response header';
ok t_cmp $resp->header('X-My-Error'), 'error', n 'response error header';
ok t_cmp $resp->content_type, 'text/slain', n 'response content-type';

$resp=POST $loc;
ok t_cmp $resp->code, 302, n 'POST => 302';
ok t_cmp $resp->header('Location'), qr#^(?!\Q$loc\E)#, n 'Location ne '.$loc;
ok t_cmp $resp->header('Location'), qr!\Q$hostport\E/proxy/mp/method\?-redirect-[A-Za-z0-9@=-]{32}$!, n 'Location';
ok t_cmp $dbh->selectall_arrayref
           ('SELECT data FROM p200 WHERE session=?', {},
	    substr( $resp->header('Location'), -32 ).':00000004')->[0]->[0],
         'POST:', n 'POST result in DB';

ok t_cmp GET($resp->header('Location'))->content, 'POST:', n 'POST content=POST';

t_debug "the next step may take a while - a 10MB document is fetched";
$resp=POST '/proxy/mp/big';

t_debug "POST request done. Now following the Location header.";
t_debug "  ".$resp->header('Location');
my ($x,$nox)=(0,0);
$resp=Apache::TestRequest::user_agent->get
  ( $resp->header('Location'), ':content_cb'=>sub {
      $x+=$_[0]=~tr/y//;
      $nox+=$_[0]=~tr/y//c;
    } );
ok t_cmp $x, 1024*10240, n 'read 1024 chunks of 10240 bytes';
ok t_cmp $nox, 0, n 'and no unexpected bytes';

# Local Variables: #
# mode: cperl #
# End: #
