BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

use Class::Maker qw(class); #qw(class reflect);

#use Object::Debugable qw(:all);

$Class::Maker::DEBUG = 0;

::class 'TestClass',
{
	public =>
	{
		scalar => [qw(attr)],
	}
};

sub TestClass::print_attr
{
	my $this = shift;

		print $this->attr, "\n";
}

sub TestClass::alibi
{
	return 1;
}

package FOO;

::class 'TestClass',
{
	isa => [qw(TestClass)],

	public =>
	{
		scalar => [qw(attr)],
	}
};

package BAR;

::class 'ParentClass',
{
	isa => [qw( FOO::TestClass )],

	public =>
	{
		scalar => [qw(attr)],
	}
};

::class 'main::TestClass2',
{
	isa => [qw( .ParentClass )],

	public =>
	{
		scalar => [qw(attr)],
	}
};

sub main::TestClass2::print_attr
{
	my $this = shift;

		print $this->attr, "\n";
}

package main;

	#debugSymbols( 'CORE::GLOBAL::', 'main::FOO::TestClass::', 'mainClass::Maker::', 'main::TestClass::', 'main::FOO::' , 'main::BAR::', 'main::TestClass2::',);

	my $obj;

	$obj = TestClass->new( attr => 'i am an TestClass object' );
	$obj = new TestClass( attr => 'i am an TestClass object' );

	$obj->print_attr;

	$obj = TestClass2->new( attr => 'i am an TestClass2 object' );
	$obj = new TestClass2( attr => 'i am an TestClass2 object' );

	$obj->alibi();
	$obj->print_attr;

	$obj = FOO::TestClass->new( attr => 'i am an FOO::TestClass object' );
	$obj = new FOO::TestClass( attr => 'i am an FOO::TestClass object' );

	$obj->alibi();

	foreach ( qw( FOO::TestClass main::TestClass2 ) )
	{
		print "\nRelection of $_\n";

		#debugDump( reflect( $_ ) );
	}

	eval
	{
		1;
	};

	if($@)
	{
		croak "Exception caught: $@\n";

		print 'not ';
	}

printf "ok %d\n", ++$loaded;

__END__
