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

plan tests=>4, have_module qw(mod_rewrite mod_cgi);

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

t_write_perl_script( t_catfile( $docroot, qw/cgi chunks/ ), <DATA> );

######################################################################
## the real tests begin here                                        ##
######################################################################

my $resp=POST '/cgi/chunks';
my $loc=$resp->header('Location');
my $chunk=$dbh->selectall_arrayref
  ('SELECT data FROM p200 WHERE session=?', {},
   substr( $loc, -32 ).':00000005')->[0]->[0];
ok t_cmp scalar($chunk=~/^x+$/), 1, n 'chunked: checking 2nd chunk';

$chunk=$dbh->selectall_arrayref
  ('SELECT data FROM p200 WHERE session=?', {},
   substr( $loc, -32 ).':00000006')->[0]->[0];
ok t_cmp scalar($chunk=~/^x+$/), 1, n 'chunked: checking 3rd chunk';

$resp=GET $loc;
ok t_cmp length($resp->content), 81920, n 'chunked: content length';
ok t_cmp scalar($resp->content=~/^x+$/), 1, n 'chunked: content is /^x+$/';

__DATA__
use strict;

$|=1;

print "Content-Type: text/plain\n\n";
print 'x'x8192 for (1..10);

# Local Variables: #
# mode: cperl #
# End: #
