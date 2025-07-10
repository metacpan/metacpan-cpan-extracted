use strict;
use warnings;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/../lib";

use DB::Berkeley;

my $dbfile = "test3.db";
unlink $dbfile if -e $dbfile;

my $db = DB::Berkeley->new($dbfile, 0, 0666);
ok($db, 'Created DB');

$db->put($_, uc($_)) for qw(one two three);

my @vals = sort @{$db->values};
cmp_deeply(\@vals, [qw(ONE THREE TWO)], 'values() returns all expected');

$db->rewind();
my @pairs;
while (my $pair = $db->each) {
	push @pairs, $pair;
}

cmp_deeply(
	[ sort map { join '=', @$_ } @pairs ],
	[ 'one=ONE', 'three=THREE', 'two=TWO' ],
	'each() returns expected key=value pairs'
);

done_testing();

END {
    unlink $dbfile if -e $dbfile;
}
