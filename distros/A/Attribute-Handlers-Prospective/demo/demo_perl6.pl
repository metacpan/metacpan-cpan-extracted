use TestBed6;

INIT {$X = 99}

package other;
 
sub x
	is Attr('an attribute')
	   Attr(1..10)
	   Attr($X)
	   Attr([$X])
	   Another_Attr {
	print @_;
}

x(1,2,3,4,5,6);

package here;

for (1..3) {
	my $y is VarAttr('an attribute')
		 VarAttr(1..10)
		 VarAttr($X)
		 VarAttr([$X])
		 Another_Attr = 7;

	my $z = sub is Attr('anon') { print "ymous\n" };

	print $y, "\n";
	$z->();
	}
