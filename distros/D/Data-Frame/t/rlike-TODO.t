use Test::Most tests => 1;

use strict;
use warnings;

use Data::Frame::Rlike;

my @to_implement = qw( merge by cbind rbind nrow ncol attach detach unique duplicated dim names str summary all any empty lapply );

my $df_rlike = dataframe();

TODO: {
	local $TODO = "R-like functions to implement: @to_implement";

	can_ok( $df_rlike, @to_implement );
}

done_testing;
