use Test::More;

use Basic::Types::XS qw/Bool/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $sub = sub { return 2 };

is(Bool->(1), 1);
is(Bool->(0), 0);
my $bool = \1;
is(Bool->($bool), $bool);
$bool = \0;
is(Bool->($bool), $bool);
$bool = \"";
is(Bool->($bool), $bool);
is(Bool->(""), "");

$bool = \undef;
is(Bool->($bool), $bool);
is(Bool->(undef), undef);

eval {
	Bool->($num);
};

like($@, qr/value did not pass type constraint "Bool"/);


eval {
	Bool->($num2);
};

like($@, qr/value did not pass type constraint "Bool"/);


eval {
	Bool->($d);
};

like($@, qr/value did not pass type constraint "Bool"/);


eval {
	Bool->($d2);
};

like($@, qr/value did not pass type constraint "Bool"/);






eval {
	Bool->($str);
};

like($@, qr/value did not pass type constraint "Bool"/);

eval {
	Bool->($invalid);
};

like($@, qr/value did not pass type constraint "Bool"/);


eval {
	Bool->($hash);
};

like($@, qr/value did not pass type constraint "Bool"/);

eval {
	Bool->($array);
};

like($@, qr/value did not pass type constraint "Bool"/);

eval {
	Bool->($sub);
};

like($@, qr/value did not pass type constraint "Bool"/);


ok(1);

done_testing();
