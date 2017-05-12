#! perl

use strict;
use warnings;

use Test::More;
BEGIN {
	eval "use Test::Exception; 1"
		or plan skip_all => "Test::Exception required to test construction.";
	plan tests => 4;
}


use Algorithm::RabinKarp;

my $hash_generator;
lives_ok { 
	$hash_generator = Algorithm::RabinKarp->new(6, "test 1");
} "Can construct a hash generator with a scalar";

lives_ok { 
	my $i = 1;
	my $code_stream = sub {
		$i++;
		return $i, $i;
	};
	$hash_generator = Algorithm::RabinKarp->new(6, $code_stream);
} "Can construct a hash generator with a code ref";

lives_ok {
	my $fh = *DATA;
	$hash_generator = Algorithm::RabinKarp->new(6, $fh);
} "Can construct a hash generator with a glob";

dies_ok {
	Algorithm::RabinKarp->new(6, undef);
} qr/Algorithm::RabinKarp requires its source stream be one of the following types:/;

__DATA__
test
test
test2
test3
