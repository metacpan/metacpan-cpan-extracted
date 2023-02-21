use Test::More;
use Data::Dump::Streamer qw(Dump);

my $dump= Dump(\%::);
pass("Dumping the stash did not die");
done_testing;
