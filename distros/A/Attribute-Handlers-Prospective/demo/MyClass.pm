package MyClass;
use v5.6.0;
use Attribute::Handlers::Prospective;

sub Bad : ATTR(SCALAR) {
	# Invoked for any scalar variable with a :Bad attribute,
	# provided the variable was declared in MyClass (or
	# a derived class) or typed to MyClass.
	local $" = ", ";
	print "MyClass::Bad:ATTR(SCALAR)(@_);\n";
}

sub Good : ATTR(SCALAR,ARRAY,HASH) {
        # Invoked for any array variable with a :Good attribute,
        # provided the variable was declared in MyClass (or
        # a derived class) or typed to MyClass.
	local $" = ", ";
	print "MyClass::Good:ATTR(",ref $_[2],")(@_);\n";
};

sub Ugly : ATTR(CODE) {
        # Invoked for any subroutine declared in MyClass (or a 
        # derived class) with an :Ugly attribute.
	local $" = ", ";
	print "MyClass::UGLY:ATTR(CODE)(@_);\n";
};

sub Omni : ATTR {
        # Invoked for any scalar, array, hash, or subroutine
        # with an :Omni attribute, provided the variable or
        # subroutine was declared in MyClass (or a derived class)
        # or the variable was typed to MyClass.
        # Use ref($_[2]) to determine what kind of referent it was.
	local $" = ", ";
	my $type = ref $_[2];
	print "MyClass::OMNI:ATTR($type)(@_);\n";
	use Data::Dumper 'Dumper';
	print Dumper [ \@_ ];
};

1;
