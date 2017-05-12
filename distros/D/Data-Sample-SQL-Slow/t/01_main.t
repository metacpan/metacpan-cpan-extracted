use strict;
use Test::More;
use Data::Dumper;
use Data::Sample::SQL::Slow;
use Carp;

my %slow = (
    time => time,
    query => 'SELECT * FROM trials WHERE name LIKE "%hoge%"',
    id => 1,
    query_time => 0.1,
    lock_time => 0.1,
    rows_sent => 1,
    rows_examined => 10
    );
    
my $query = Data::Sample::SQL::Slow->new(%slow);
is $query->toStr(), "# Time: $slow{time}
# User\@Host: hoge[hoge] @ localhost []  Id: $slow{id}
# Query_time: $slow{query_time}  Lock_time: $slow{lock_time} Rows_sent: $slow{rows_sent}  Rows_examined: $slow{rows_examined}
SET timestamp=$slow{time}
$slow{query}";

done_testing;
