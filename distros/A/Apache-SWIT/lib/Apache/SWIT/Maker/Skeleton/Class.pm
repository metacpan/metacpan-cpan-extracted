use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Class;
use base 'Apache::SWIT::Maker::Skeleton';

sub output_file {
	my $res = 'lib/' . shift()->class_v . ".pm";
	$res =~ s/::/\//g;
	return $res;
}

1;
