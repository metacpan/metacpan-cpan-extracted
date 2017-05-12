#################################################################
#
#   $Id: 06_test_cache.t,v 1.2 2006/04/28 14:35:53 erwan Exp $
#
#   Test that caching the sequence index works well
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
    plan tests => 5;
};

require MockDB::BookCache;

my $book1 = MockDB::BookCache->insert({author => 'me', title => 'my life'});
is($book1->seqid,0,"seqid after insert");
is($book1->author,'me',"author after insert");

my $book2 = MockDB::BookCache->insert({seqid => 3, author => 'him', title => 'his life'});
is($book2->seqid,3,"seqid after insert with provided seqid");
is($book2->author,'him',"author after insert");

my $book3 = MockDB::BookCache->insert({author => 'they', title => 'their life'});
is($book3->seqid,1,"seqid after insert, index calculated from cache");







