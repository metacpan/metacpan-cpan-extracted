use strict;
use Data::Dumper;
use Amethyst::Store;

my $file = shift @ARGV;

my $store = new Amethyst::Store(
		Source	=> $file,
			);

my @keys = sort $store->keys;

print Dumper(\@keys);

foreach my $key (@keys) {
	print "$key : " . Dumper($store->get($key));
}
