use strict;
use warnings FATAL => 'all';

package T::Basic;
use Apache::SWIT::Security qw(Sealed_Params);
 
sub handler {
	my $r = shift;
	my ($a, $c) = Sealed_Params(Apache2::Request->new($r), 'a', 'c');
	$a ||= "NONE";
	$c ||= "NONE";
	$r->content_type("text/plain");
	print "hhhh\n$INC[0]\na=$a\nc=$c\n";

	my $s = $r->pnotes('SWITSession');
	print "no params denied\n" unless $s->is_allowed('/test/foo');
	print "random params denied\n" unless $s->is_allowed('/test/foo?a=b');
	print "params allowed\n" if $s->is_allowed('/test/foo?qqq=1');
	return Apache2::Const::OK();
}

1;
