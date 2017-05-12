#################################################################
#
#   $Id: 05_test_step.t,v 1.2 2006/04/28 14:35:53 erwan Exp $
#
#   This test verifies that AutoIncrement works when
#   there is a min value and an increment step defined
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
    plan tests => 4;
};

require MockDB::BookStep;

my @handles = MockDB::BookStep->db_handles(); 
my $dbc = shift @handles;
my $rs;

$rs = $dbc->prepare("INSERT INTO book (seqid,author) VALUES (3,'bob')");
$rs->execute();
$rs = $dbc->prepare("INSERT INTO book (seqid,author) VALUES (5,'bil')");
$rs->execute();

my $book1 = MockDB::BookStep->insert({author => 'me', title => 'my life'});
is($book1->seqid,7,"seqid after insert");
is($book1->author,'me',"author after insert");

my $book2 = MockDB::BookStep->insert({author => 'me', title => 'yet again'});
is($book2->seqid,9,"seqid after insert");
is($book2->author,'me',"author after insert");
