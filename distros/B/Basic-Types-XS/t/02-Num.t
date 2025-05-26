use Test::More;

use Basic::Types::XS qw/Num/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $sub = sub { return 2 };

is(Num->($num), 123);
is(Num->($num2), 123);
is(Num->($d), 123.123);
is(Num->($d2), 123.123);

eval {
	Num->($str);
};

like($@, qr/value did not pass type constraint "Num"/);

eval {
	Num->($invalid);
};

like($@, qr/value did not pass type constraint "Num"/);



eval {
	Num->(undef);
};

like($@, qr/value did not pass type constraint "Num"/);

eval {
	Num->($hash);
};

like($@, qr/value did not pass type constraint "Num"/);

eval {
	Num->($array);
};

like($@, qr/value did not pass type constraint "Num"/);

eval {
	Num->($sub);
};

like($@, qr/value did not pass type constraint "Num"/);


ok(1);

done_testing();
