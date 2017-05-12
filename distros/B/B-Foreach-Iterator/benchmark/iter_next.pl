#!perl -w

use Benchmark qw(:all);

use B::Foreach::Iterator;

my @ary = %ENV;

sub f{
	my($key, $val) = @_;
	# no-op
}

print "For key-val pairs\n";
cmpthese -1 => {
	'for' => sub{
		for(my $i = 0; $i < @ary; $i += 2){
			my $key = $ary[$i];
			my $val = $ary[$i+1];

			f($key => $val);
		}
	},
	'iter_next' => sub{
		foreach my $key(@ary){
			my $val = iter->next();

			f($key => $val);
		}
	},
};

