package CookBookA::Ex4;

require DynaLoader;
@ISA = 'DynaLoader';

$VERSION = '49.1';

bootstrap CookBookA::Ex4 $VERSION;

# Constructor for class CookBookA::Ex4.
sub new {
	my $type = shift;
	bless [], $type;
}

# There are two C-based classes in this module.  The first
# is CookBookA::Ex4 and the second is CookBookA::Ex4A.  We
# want the second to be a subclass of the first.  Class CookBookA::Ex4A
# has its own C-based constructor which will override the constructor
# in CookBookA::Ex4, but CookBookA::Ex4A will use all of the methods
# in CookBookA::Ex4.

@CookBookA::Ex4A::ISA = 'CookBookA::Ex4';

1;
