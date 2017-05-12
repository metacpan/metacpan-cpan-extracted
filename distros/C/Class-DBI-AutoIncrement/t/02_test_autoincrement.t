#################################################################
#
#   $Id: 02_test_autoincrement.t,v 1.1.1.1 2006/04/28 13:58:15 erwan Exp $
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
    plan tests => 11;
};

require MockDB::Book;

my $book1 = MockDB::Book->insert({author => 'me', title => 'my life'});
is($book1->seqid,0,"seqid after insert");
is($book1->author,'me',"author after insert");

my $book2 = MockDB::Book->insert({author => 'him', title => 'his life'});
is($book2->seqid,1,"seqid after insert");
is($book2->author,'him',"author after insert");

my $book3 = MockDB::Book->find_or_create({seqid => 1});
is_deeply($book3,$book2,"find_or_create on existing element (based on seqid)");

my $book4 = MockDB::Book->find_or_create({author => 'him', title => 'his life'});
is_deeply($book3,$book2,"find_or_create on existing element (based on other fields)");

my $book5 = MockDB::Book->find_or_create({author => 'they', title => 'their life'});
is($book5->seqid,2,"find_or_create initiated seqid upon creating");
is($book5->title,'their life',"title after insert");

my $book6 = MockDB::Book->create({author => 'it', title => 'its life'});
is($book6->seqid,3,"test create");

my $book7 = MockDB::Book->insert({seqid => 4, author => 'it', title => 'its life'});
is($book7->seqid,4,"test insert with provided seqid");

my $book8 = MockDB::Book->insert({author => 'me', title => 'my secret life'});
is($book8->seqid,5,"test index cache is off by default");







