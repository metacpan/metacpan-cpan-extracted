#! /usr/bin/perl
#
# test page
#

use Todo::Server;
use Crop::Debug;

my $Server = Todo::Server->new;

$Server->add_handler(DEFAULT => {
	call => sub {
		my $S = shift;
		my $O = $S->O;

		$O->{test} = 25;

		OK;
	},
});

$Server->listen;