use strict;
use warnings FATAL => 'all';

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;		# import default
use Apache::TestUtil qw{t_write_perl_script t_catfile};
use Apache::TestRequest qw{GET POST};
use Apache2::Const -compile=>qw{:options};
use DBI;
use DBD::SQLite;

plan tests=>15, have_module qw(mod_rewrite mod_cgi);

my $docroot=Apache::Test::vars->{documentroot};
my $serverroot=Apache::Test::vars->{serverroot};
my $hostport = Apache::TestRequest::hostport() || '';
t_debug("connecting to $hostport");

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

t_write_perl_script( t_catfile( $docroot, qw/cgi method/ ), <DATA> );

######################################################################
## the real tests begin here                                        ##
######################################################################

my $resp=GET '/cgi/method';
ok t_cmp $resp->code, 200, n 'GET => 200';
ok t_cmp $resp->content, 'GET:', n 'GET content=GET';

$resp=POST '/cgi/method';
my $loc=$resp->header('Location');
ok t_cmp $resp->code, 302, n 'POST => 302';
ok t_cmp $loc, qr!\Q$hostport\E/cgi/method\?-redirect-[A-Za-z0-9@=-]{32}$!, n 'Location';
ok t_cmp $dbh->selectall_arrayref
           ('SELECT data FROM p200 WHERE session=?', {},
	    substr( $loc, -32 ).':00000002')->[0]->[0],
         "X-My-Header: hallo opi\n", n 'checking my header';

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
ok t_cmp $resp->content_type, 'text/slain', n 'response content-type';

$resp=POST $loc;
ok t_cmp $resp->code, 302, n 'POST => 302';
ok t_cmp $resp->header('Location'), qr#^(?!\Q$loc\E)#, n 'Location ne '.$loc;
ok t_cmp $resp->header('Location'), qr!\Q$hostport\E/cgi/method\?-redirect-[A-Za-z0-9@=-]{32}$!, n 'Location';
ok t_cmp $dbh->selectall_arrayref
           ('SELECT data FROM p200 WHERE session=?', {},
	    substr( $resp->header('Location'), -32 ).':00000004')->[0]->[0],
         'POST:', n 'POST result in DB';

ok t_cmp GET($resp->header('Location'))->content, 'POST:', n 'POST content=POST';

__DATA__
use strict;

print "Content-Type: text/slain\n";
print "X-My-Header: hallo opi\n";
print "\n";
print "$ENV{REQUEST_METHOD}:$ENV{QUERY_STRING}";

# Local Variables: #
# mode: cperl #
# End: #
