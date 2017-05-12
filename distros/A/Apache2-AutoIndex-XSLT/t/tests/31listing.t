use strict;
use warnings FATAL => 'all';
  
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
  
my %items = (
		updir => 1,
		dir => 2,
		file => 5,
	);

plan tests => scalar(keys(%items));
  
my $url = '/test/';
my $data = GET_BODY $url ;

while (my ($item,$total) = each %items) {
	my (@actual) = $data =~ /(<$item\s+.*?\s+\/>)/msg;
	ok t_cmp(
		scalar(@actual),
		$total,
		"$total ${item}'s"
	);
}

