use Test::More;

use Basic::Types::XS qw/CodeRef/;

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

is(CodeRef->($sub), $sub);

eval {
	CodeRef->($num);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($num2);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($d);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($d2);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($str);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($invalid);
};

like($@, qr/value did not pass type constraint "CodeRef"/);


eval {
	CodeRef->(undef);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($hash);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($array);
};

like($@, qr/value did not pass type constraint "CodeRef"/);

eval {
	CodeRef->($blessed);
};

like($@, qr/value did not pass type constraint "CodeRef"/);



ok(1);

done_testing();
