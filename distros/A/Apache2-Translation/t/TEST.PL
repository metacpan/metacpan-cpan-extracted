#!perl

use strict;
use warnings FATAL => 'all';
use DBI;
use DBD::SQLite;

use lib "../lib"; # test against the source lib for easier dev
use lib map {("../blib/$_", "../../blib/$_")} qw(lib arch);

my ($db,$user,$pw,$dbinit)=@ENV{qw/DB USER PW/};

package MyTest;

use Apache::Test ();
use Apache::TestUtil qw(t_catfile);
use Apache::TestRunPerl ();
use base qw(Apache::TestRunPerl);

# subclass new_test_config to add some config vars which will be
# replaced in generated httpd.conf
sub new_test_config {
  my $self=shift;
  $self->{conf_opts}->{maxclients}=2;
  $self=$self->SUPER::new_test_config;

  my $serverroot=Apache::Test::vars->{serverroot};
  my $confdir=Apache::Test::vars->{t_conf};

  unless( defined $db and length $db ) {
    ($db,$user,$pw)=("dbi:SQLite:dbname=$serverroot/test.sqlite", '', '');
    $dbinit="PRAGMA synchronous = OFF";
  }
  warn "# Using Database $db, User '$user'\n";

  my $dbh=DBI->connect( $db, $user, $pw,
			{AutoCommit=>1, PrintError=>0, RaiseError=>1} )
    or die "ERROR: Cannot connect to $db: $DBI::errstr\n";

  eval {$dbh->do('PRAGMA synchronous = OFF')} if( defined $dbinit );
  eval {$dbh->do('DROP TABLE cache')};
  eval {$dbh->do('CREATE TABLE cache ( v int )')};
  eval {$dbh->do('INSERT INTO cache( v ) VALUES( 1 )')};
  eval {$dbh->do('DROP TABLE sequences')};
  eval {$dbh->do('CREATE TABLE sequences ( xname text, xvalue int )')};
  eval {$dbh->do('DROP TABLE trans')};
  eval {
    $dbh->do( <<'SQL' );
CREATE TABLE trans ( id int, xkey text, xuri text, xblock int, xorder int, xaction text, xnotes text )
SQL
  };
  $dbh->disconnect;

  open my $f, ">$confdir/db.inc" or
    die "ERROR: Cannot write to $confdir/db.inc: $!\n";
  do {
    no warnings 'uninitialized';
    if( $ENV{INTERP_SCOPE} ) {
      warn "# Using PerlInterpScope $ENV{INTERP_SCOPE}\n";
      print $f <<"EOF";
<IfModule worker.c>
    PerlInterpScope $ENV{INTERP_SCOPE}
</IfModule>
EOF
    }
    if( $ENV{OLD_INTERFACE} ) {
      print $f <<"EOF";
TranslationProvider DB \\
		    "Database=$db" \\
		    "User=$user" "Password=$pw" \\
		    table=trans \\
		    key=xkey uri=xuri block=xblock order=xorder action=xaction id=id \\
		    cachetbl=cache cachecol=v singleton=1
EOF
    } else {
    print $f <<"EOF";
<TranslationProvider DB>
    Database  "$db"
    User      "$user"
    Password  "$pw"
    Table     trans
    Id        id
    Key       xkey
    Uri       xuri
    Block     xblock
    Order     xorder
    Action    xaction
    Cachetbl  cache
    Cachecol  v
    Singleton 1
</TranslationProvider>
EOF
    }
  };
  close $f or
    die "ERROR: Cannot write to $confdir/db.inc: $!\n";

  return $self;
}

my($argv, $vars) =
  Apache::TestConfig::filter_args(\@ARGV, \%Apache::TestConfig::Usage);
%Apache::TestConfig::Argv = %$vars;

my $t=MyTest->new->run(@ARGV);
