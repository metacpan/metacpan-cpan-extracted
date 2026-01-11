use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Local::Foo;
	use Class::XSConstructor qw( foo !! );
}

my $o = Local::Foo->new( foo => 42 );
is($o->{foo}, 42);

like(
	exception { Local::Foo->new( bar => 66 ) },
	qr/Found unknown attribute passed to the constructor: bar/,
);

push @{ Class::XSConstructor::get_metadata('Local::Foo')->{allow} }, 'bar';
Local::Foo->XSCON_CLEAR_CONSTRUCTOR_CACHE;

is(
	exception { Local::Foo->new( bar => 66 ) },
	undef,
);

done_testing;
