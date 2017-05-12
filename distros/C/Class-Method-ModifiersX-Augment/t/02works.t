use strict;
use Test::More;

{
	package Document;
	use Class::Method::ModifiersX::Augment;
	sub new       { my ($class, %self) = @_; bless \%self, $class }
	sub recipient { $_[0]{recipient} }
	sub as_xml    { sprintf "<document>%s</document>", inner }
}

{
	package Greeting;
	BEGIN { our @ISA = 'Document' };
	use Class::Method::ModifiersX::Augment;
	augment as_xml => sub {
		sprintf "<greet>%s</greet>", inner
	}
}

{
	package Greeting::English;
	BEGIN { our @ISA = 'Greeting' };
	use Class::Method::ModifiersX::Augment;
	augment as_xml => sub {
		my $self = shift;
		sprintf "Hello %s", $self->recipient;
	}
}

my $obj1 = Document->new(recipient => "World");
is(
	$obj1->as_xml,
	"<document></document>",
);

my $obj2 = Greeting->new(recipient => "World");
is(
	$obj2->as_xml,
	"<document><greet></greet></document>",
);

my $obj3 = Greeting::English->new(recipient => "World");
is(
	$obj3->as_xml,
	"<document><greet>Hello World</greet></document>",
);

done_testing();
