package TestApp::boot;

use strict;
use warnings;

our @EXPORT_OK = qw( &res );

use base 'Exporter';
use File::Spec::Functions qw( catfile splitpath );
use FindBin qw( $Bin );
use DBI;


sub res {open FH,File::Spec->catfile($Bin,'ok',shift) or die $!;<FH>}

my $db = catfile((splitpath( __FILE__ ))[1],'..','..','test.db');
return 1 if -f $db && -s _;

my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","", { RaiseError=>1 });
$dbh->do('CREATE TABLE user ( id INTEGER PRIMARY KEY, name TEXT )');
my $sth = $dbh->prepare('INSERT INTO user VALUES(?,?)');
$sth->execute( $_, 'user-' . $_ ) for 1 .. 1_000;

1;

