#################################################################
#
#   $Id: DBI.pm,v 1.1.1.1 2006/04/28 13:58:15 erwan Exp $
#

package MockDB::DBI;

use strict;
use warnings;
use File::Temp qw(tempfile);
use base qw(Class::DBI);

my($fh,$name) = tempfile(undef, UNLINK => 1);
$fh->close;
__PACKAGE__->set_db('test',"dbi:SQLite:$name");

my @handles = __PACKAGE__->db_handles(); 
my $dbc = shift @handles;
my $rs;

$rs = $dbc->prepare("CREATE TABLE book (seqid NUMBER NOT NULL PRIMARY KEY, author VARCHAR(100), title VARCHAR(100), isbn NUMBER)");
$rs->execute();

#$rs = $dbc->prepare("CREATE TABLE blob (seqid NUMBER NOT NULL PRIMARY KEY, blob VARCHAR(100))");
#$rs->execute();

1;
