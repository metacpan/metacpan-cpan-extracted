#!perl

use strict;
use warnings FATAL => 'all';

my %tables = (
  pkit_user => q{
    CREATE 
      TABLE pkit_user (
        user_id CHAR(8), 
        login   CHAR(255), 
        email   CHAR(255), 
        passwd  CHAR(255)
      )
  },
  sessions => q{
    CREATE 
      TABLE sessions (
        id char(32) not null primary key,
        a_session text
      )
  }
);

use mod_perl2;

# required for example web site to run
use DBD::SQLite;
use Digest::MD5;
use Cwd;
use File::Path;
use Apache::Test 1.05;
use Apache::TestRunPerl ();
use File::Spec::Functions qw(catfile);

sub table_exists {
  my ( $dbh, $table ) = @_;
  eval {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    $dbh->do(qq{SELECT * FROM $table WHERE 1 = 0 });
  };
  return !$@;
}

my ( $root_found, $pkit_root );
for ( 0 .. $#ARGV ) {
  if ( $ARGV[$_] =~ /-documentroot$/ ) {
    $root_found++;
    $pkit_root = $ARGV[ $_ + 1 ];
    last;
  }
}

$pkit_root ||= catfile( Cwd::getcwd(), 'eg' );

my $dbh = DBI->connect( "dbi:SQLite:dbname=$pkit_root/dbfile",
                 "", "", { AutoCommit => 1, PrintError => 1, RaiseError => 0 } )
  or die $DBI::errstr;

for my $table ( keys %tables ) {
  unless ( table_exists( $dbh, $table ) ) {
    $dbh->do( $tables{$table} );
  }
}
$dbh->disconnect;

chmod 0666 => "$pkit_root/dbfile";

unless ($root_found) {
  push( @ARGV, '--documentroot' => $pkit_root );
  chmod 0777 => catfile( $pkit_root, 'View', 'pkit_cache' );
}

Apache::TestRunPerl->new->run(@ARGV);
1;
