package App::Scaffolder::Command::dummy;
use parent qw(App::Scaffolder::Command);

use strict;
use warnings;

sub get_dist_name {
	return 'App-Scaffolder';
}

1;