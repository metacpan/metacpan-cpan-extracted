use Test::More;

use Basic::Types::XS qw/Ref/;

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

is_deeply(Ref->($hash), { a => 1 });
is_deeply(Ref->($array), [qw/1 2 3/]);
is_deeply(Ref->($blessed), { a => 1 });
ok(Ref->($sub));
is_deeply(Ref->($ref), \1);
is_deeply(Ref->($blessed_ref), \"abc");

eval {
	Ref->($num);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->($num2);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->($d);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->($d2);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->($str);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->($invalid);
};

like($@, qr/value did not pass type constraint "Ref"/);

eval {
	Ref->(undef);
};

like($@, qr/value did not pass type constraint "Ref"/);


ok(1);

done_testing();
