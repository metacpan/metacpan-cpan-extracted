use strict;
use warnings FATAL => 'all';

package T::Basic;
 
sub handler {
	my $r = shift;
	$r->content_type("text/plain");
	print "hhhh\n$INC[0]";
	return Apache2::Const::OK();
}

1;
