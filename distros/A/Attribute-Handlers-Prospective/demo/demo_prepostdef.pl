use TestBed;

INIT {$X = 99}

package other;
use base TestBed;
 
sub x
	: Attr(an attribute)
	  Attr(1..10)
	  Attr($X)
	  Attr([$X])
	  Unknown_Attr(99)
	  Another_Attr($X) {
	print @_;
}

x(1,2,3,4,5,6);


package Little;
use base TestBed;

package ZZ;
use base TestBed;

package here;
use base TestBed;

for (1..3) {
	my Little $y : VarAttr(an attribute)
		 VarAttr(1..10)
		 VarAttr($X)
		 VarAttr([$X])
		 Unknown_VarAttr(1)
		 Another_Attr(for me) = 7;

	local $ZZ::z : VarAttr = sub : Attr('anon') { print "ymous\n" };

	print $y, "\n";
	$ZZ::z->();
	}
