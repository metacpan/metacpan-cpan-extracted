package Real;
use Attribute::Handlers::Prospective;

sub RealAttr : ATTR {
	print "You ascribed a RealAttr attribute to $_[2]\n";
}

sub AUTOATTR : ATTR {
	print ">>> You tried to ascribe a :$_[3] attribute to $_[2]\n",
	      ">>> but there's no such attribute defined in class $_[0]\n",
	      ">>> (Did you mean :RealAttr?)\n";
}

package main;

my Real $thing : FakeAttr = 7;
print "$thing\n";
