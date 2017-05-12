use Test::More 0.89;
use ok 'Data::Thunk';

use Scalar::Util qw(reftype blessed);

my $y = 0;
my $l = lazy { ++$y };

is($y, 0, "not triggered yet");

is($l, 1, "lazy value");

is($y, 1, "trigerred");

my $forced = force lazy { 4 };
is($forced, 4, 'force($x) works');
is($forced, 4, 'force($x) is stable');
is(force $forced, 4, 'force(force($x)) is stable');

$SomeClass::VERSION = 42;
sub SomeClass::meth { 'meth' };
sub SomeClass::new { bless(\@_, $_[0]) }

is(ref(lazy { SomeClass->new }), 'SomeClass', 'ref() returns true for refs');
ok(!ref(lazy { "foo" }), 'ref() returns false for simple values');
is(ref(force lazy { SomeClass->new }), 'SomeClass', 'ref() returns true for forced values');
is(lazy { SomeClass->new }->meth, 'meth', 'method call works on deferred objects');
is(lazy { SomeClass->new }->can('meth'), SomeClass->can('meth'), '->can works too');
ok(lazy { SomeClass->new }->isa('SomeClass'), '->isa works too');
is(lazy { SomeClass->new }->VERSION, SomeClass->VERSION, '->VERSION works too');

my $new = 0;
@OtherClass::ISA = qw(Bar);
sub Bar::flarp { "flarp" }
sub OtherClass::new { $new++; bless(\@_, $_[0]) };

is( $new, 0, "new not called" );

my $obj = lazy_new "OtherClass", args => [ "blah" ];
is( $new, 0, "new not called" );

is( reftype($obj), "HASH", "hash reftype" );
is( $new, 0, "new not called" );

is( ref($obj), "OtherClass", "reported class" );
is( $new, 0, "new not called" );

ok( $obj->isa("Bar"), "object isa bar" );
is( $new, 0, "new not called" );

can_ok( $obj, "flarp" );
is( $new, 0, "new not called" );

is( $obj->flarp, "flarp", "flarp method" );
is( $new, 1, "new called once" );

is( reftype($obj), "ARRAY", "hash reftype" );
is( $new, 1, "new called once" );

is_deeply( $obj, bless([ OtherClass => "blah" ], "OtherClass"), "structure" );
is( $new, 1, "new called once" );

is( ref($obj), "OtherClass", "reported class" );
is( $new, 1, "new called once" );

can_ok( $obj, "flarp" );
ok( $obj->isa("Bar"), "object isa bar" );

is( $new, 1, "new called once" );

foreach my $class ( qw( Data::Thunk::Code Data::Thunk::Object Data::Thunk::ScalarValue ) ) {
	ok( !$class->can($_), "can't call export $_ as method on $class" )
		for qw(croak carp reftype blessed swap);
}

{
	my $shared;

	my $obj = lazy { $shared = SomeClass->new("foo") };

	is( $obj->meth, "meth", "method call" );

	is( blessed($obj), "SomeClass", "thunk vivified" );
	is( blessed($shared), "SomeClass", "shared value not destroyed" );
}

done_testing;
