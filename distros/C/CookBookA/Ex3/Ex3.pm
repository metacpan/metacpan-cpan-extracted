package CookBookA::Ex3;

require DynaLoader;
@ISA = 'DynaLoader';

$VERSION = '49.1';

bootstrap CookBookA::Ex3 $VERSION;

# Constructor for class CookBookA::Ex3.
sub new {
	my $type = shift;
	bless {}, $type;
}

# There are two C-based classes in this module.  The first
# is CookBookA::Ex3 and the second is CookBookA::Ex3A.  We
# want the second to be a subclass of the first.  Class CookBookA::Ex3A
# has its own C-based constructor which will override the constructor
# in CookBookA::Ex3, but CookBookA::Ex3A will use all of the methods
# in CookBookA::Ex3.

@CookBookA::Ex3A::ISA = 'CookBookA::Ex3';


1;
