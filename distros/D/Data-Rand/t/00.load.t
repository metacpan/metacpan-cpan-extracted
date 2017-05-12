use Test::More tests => 100_003;

BEGIN {
use_ok( 'Data::Rand' );
}

diag( "Testing 100,000 no dupes Data::Rand $Data::Rand::VERSION" );

# TODO 1,000,000 = no dupes test w/ ENV

my %seen;
for my $c (1 .. 100_000) {
    my $rand = rand_data(); # do not use NS so we know export is good as per POD
    ok(!exists $seen{$rand}, "no dupe $c");
    $seen{$rand}++;
}

ok(Data::Rand::rand_data(1,['a']) eq 'a', 'gauranteed dup ok 1');
ok(Data::Rand::rand_data(1,['a']) eq 'a', 'gauranteed dup ok 2');