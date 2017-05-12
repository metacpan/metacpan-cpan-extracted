use strict;
use Data::Dumper;
use Amethyst::Store;

my $store = new Amethyst::Store(
				Source	=> 'factpack',
					);

foreach (<>) {
	next if /^\s*#/;
	next unless /=>/;

	/^(.*?)\s*=>\s*(.*)/;
	my ($key, $val) = ($1, $2);

	# $val =~ s/^<reply>\s*\$who, //;

	my $skey = lc $key;
	my $sval = lc $val;

	my $href = {
		verb	=> 'is',
			};
	$href->{key} = $key if $key ne $skey;
	$href->{val} = $val if $val ne $sval;

	my $data = $store->get($skey);
	$data->{$sval} = $href;
	$store->set($skey, $data);
}
