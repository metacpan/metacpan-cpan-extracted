use strict;
use warnings;
use Test::More;

{
	package Local::Class;
	my $x = 'a';
	sub new { bless []=> shift }
	sub foo { return $x++ }
}

{
	package Local::Subclass;
	BEGIN { our @ISA = 'Local::Class' };
	use Class::Method::ModifiersX::Override;
	override foo => sub {
		my $letter = super();
		return uc $letter;
	}
}

{
	package Local::More;
	BEGIN { our @ISA = 'Local::Subclass' };
	use Class::Method::ModifiersX::Override;
	override foo => sub {
		my $letter = super();
		return "X${letter}X";
	}
}

my $obj = Local::More::->new;
is($obj->foo, "XAX");
is($obj->foo, "XBX");
is($obj->foo, "XCX");

done_testing;
