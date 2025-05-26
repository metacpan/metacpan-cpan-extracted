use Test::More;

use Basic::Types::XS qw/ArrayRef/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $blessed = bless [qw/1 2 3/], 'Foo';
my $sub = sub { return 2 };


is_deeply(ArrayRef->($array), [qw/1 2 3/]);
is_deeply(ArrayRef->($blessed), [qw/1 2 3/]);

eval {
	ArrayRef->($num);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($num2);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($d);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($d2);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($str);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($invalid);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);



eval {
	ArrayRef->(undef);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($hash);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);

eval {
	ArrayRef->($sub);
};

like($@, qr/value did not pass type constraint "ArrayRef"/);


ok(1);

done_testing();
