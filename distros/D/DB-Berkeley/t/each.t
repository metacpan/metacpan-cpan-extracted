use strict;
use warnings;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('DB::Berkeley') }

my $dbfile = "test5.db";
unlink $dbfile if -e $dbfile;

my $db = DB::Berkeley->new($dbfile, 0, 0666);
$db->put($_, "val$_") for qw(apple banana cherry);

my %seen;
while (my $pair = $db->each()) {
	my ($k, $v) = @$pair;
	$seen{$k} = $v;
}

cmp_deeply(\%seen, {
	apple  => 'valapple',
	banana => 'valbanana',
	cherry => 'valcherry',
}, 'each() returns correct key/value pairs');

done_testing;

END { unlink $dbfile if -e $dbfile }
