#################################################################
#
#   $Id: 04_test_fetch_max_from_db.t,v 1.2 2006/04/28 14:35:53 erwan Exp $
#
#   This test verifies that AutoIncrement works when
#   filling a database table that already contain rows
#

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use lib "../lib";
use lib ".";
use lib "lib/";
use lib "t/lib/";

BEGIN {
    eval "use Class::Accessor";     plan skip_all => "Class::Accessor is required for testing Class::DBI::AutoIncrement" if $@;
    eval "use Class::DBI";          plan skip_all => "Class::DBI is required for testing Class::DBI::AutoIncrement" if $@;
    eval "use DBD::SQLite";         plan skip_all => "DBD::SQLite is required for testing Class::DBI::AutoIncrement" if $@;
    eval "use File::Temp";          plan skip_all => "File::Temp is required for testing Class::DBI::AutoIncrement" if $@;
    plan tests => 2;
};

require MockDB::Book;

my @handles = MockDB::Book->db_handles(); 
my $dbc = shift @handles;
my $rs;

$rs = $dbc->prepare("INSERT INTO book (seqid,author) VALUES (3,'bob')");
$rs->execute();
$rs = $dbc->prepare("INSERT INTO book (seqid,author) VALUES (5,'bil')");
$rs->execute();

my $book1 = MockDB::Book->insert({author => 'me', title => 'my life'});
is($book1->seqid,6,"seqid after insert");
is($book1->author,'me',"author after insert");
