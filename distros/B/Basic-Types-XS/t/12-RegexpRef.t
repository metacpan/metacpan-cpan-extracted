use Test::More;

use Basic::Types::XS qw/RegexpRef/;

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

my $reg = qr/abc/;

is(RegexpRef->($reg), $reg);

eval {
	RegexpRef->($num);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($num2);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($d);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($d2);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($str);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($invalid);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);


eval {
	RegexpRef->(undef);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($hash);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($array);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($blessed);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

eval {
	RegexpRef->($sub);
};

like($@, qr/value did not pass type constraint "RegexpRef"/);

ok(1);

done_testing();
