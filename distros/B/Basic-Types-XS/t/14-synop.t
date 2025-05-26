use Test::More;


BEGIN {
    eval {
                require Moo;
                1;
        } or do {
        plan skip_all => "Moo is not available";
    };
}


{
	package Foo;

	use Moo;
	use Basic::Types::XS qw/Str Num Int ArrayRef HashRef/;

	has string => (
		is       => 'ro',
		isa      => Str,
		required => 1,
	);

	has num => (
		is       => 'ro',
		isa      => Num,
	);
   
	has int => (
		is       => 'rw',
		isa      => Int,
	);
   
	has array => (
		is       => 'ro',
		isa      => ArrayRef,
		default  => sub { return [] },
	);

	has hash => (
		is       => 'ro',
		isa      => HashRef,
		default  => sub { return {} },
	);

	1;
}

my $foo = Foo->new(
	string => 'abc',
	num => 123.345,
	int => 123,
	array => [ qw/1 2 3/ ],
	hash => { a => 1 }
);

is($foo->string, 'abc');
is($foo->num, 123.345);
is($foo->int, 123);
is_deeply($foo->array, [qw/1 2 3/]);
is_deeply($foo->hash, { a => 1 });

eval {
	my $foo = Foo->new(
		string => ['abc'],
		num => 123.345,
		int => 123,
		array => [ qw/1 2 3/ ],
		hash => { a => 1 }
	);
};

like($@, qr/value did not pass type constraint "Str"/);

done_testing();
