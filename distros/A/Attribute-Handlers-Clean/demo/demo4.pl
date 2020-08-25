use Descriptions;

my $capacity : Name(capacity)
	     : Purpose(to store max storage capacity for files)
	     : Unit(Gb);

package Other;
use Descriptions;

sub foo : Purpose(to foo all data before barring it) { }
