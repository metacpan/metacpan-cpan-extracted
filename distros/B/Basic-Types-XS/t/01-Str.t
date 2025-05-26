use Test::More;

use Basic::Types::XS qw/Str/;

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";

my $hash = { a => 1 };
my $array = [ qw/1 2 3/ ];
my $sub = sub { return 2 };

is(Str->($str), 'abc');
is(Str->($num), 123);
is(Str->($num2), 123);
is(Str->($d), 123.123);
is(Str->($d2), 123.123);

eval {
	Str->(undef);
};

like($@, qr/value did not pass type constraint "Str"/);

eval {
	Str->($hash);
};

like($@, qr/value did not pass type constraint "Str"/);

eval {
	Str->($array);
};

like($@, qr/value did not pass type constraint "Str"/);

eval {
	Str->($sub);
};

like($@, qr/value did not pass type constraint "Str"/);


ok(1);

done_testing();
