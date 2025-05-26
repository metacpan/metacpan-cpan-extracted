use Test::More;

use Basic::Types::XS qw/Int/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $sub = sub { return 2 };

is(Int->($num), 123);
is(Int->($num2), 123);

eval {
	Int->($d);
};

like($@, qr/value did not pass type constraint "Int"/);


eval {
	Int->($d2);
};

like($@, qr/value did not pass type constraint "Int"/);

eval {
	Int->($str);
};

like($@, qr/value did not pass type constraint "Int"/);

eval {
	Int->($invalid);
};

like($@, qr/value did not pass type constraint "Int"/);



eval {
	Int->(undef);
};

like($@, qr/value did not pass type constraint "Int"/);

eval {
	Int->($hash);
};

like($@, qr/value did not pass type constraint "Int"/);

eval {
	Int->($array);
};

like($@, qr/value did not pass type constraint "Int"/);

eval {
	Int->($sub);
};

like($@, qr/value did not pass type constraint "Int"/);


ok(1);

done_testing();
