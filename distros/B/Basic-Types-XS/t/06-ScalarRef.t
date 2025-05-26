use Test::More;

use Basic::Types::XS qw/ScalarRef/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $blessed = bless { a => 1 }, 'Foo';
my $sub = sub { return 2 };
my $ref = \1;
my $blessed_ref = bless \$str, "Boo";

is_deeply(ScalarRef->($ref), \1);
is_deeply(ScalarRef->($blessed_ref), \"abc");

eval {
	ScalarRef->($hash);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($blessed);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($num);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($num2);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($d);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($d2);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($str);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($invalid);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);



eval {
	ScalarRef->(undef);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($array);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);

eval {
	ScalarRef->($sub);
};

like($@, qr/value did not pass type constraint "ScalarRef"/);


ok(1);

done_testing();
