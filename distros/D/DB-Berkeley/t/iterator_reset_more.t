use strict;
use warnings;
use Test::Most;
use DB::Berkeley;

my $file = "t/iterator_reset.db";
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

# Populate the DB
my %input = (
    apple  => 'red',
    banana => 'yellow',
    grape  => 'purple',
);

while (my ($k, $v) = each %input) {
    ok($db->put($k, $v), "put($k => $v)");
}

# First iteration
my %seen;
while (my $pair = $db->each()) {
	my ($k, $v) = @$pair;
	$seen{$k} = $v;
}
cmp_deeply(\%seen, \%input, "First each() iteration collected all key/value pairs");

# Iterator should now be at end
ok(!defined($db->each()), "Iterator returns undef at end");

# Second iteration — should reset
$db->iterator_reset();
my %seen2;
while (my $pair = $db->each()) {
	my ($k2, $v2) = @$pair;
	$seen2{$k2} = $v2;
}
cmp_deeply(\%seen2, \%input, "Second each() after reset collects full set again");

# Done
done_testing();

END {
    unlink $file if -e $file;
}
