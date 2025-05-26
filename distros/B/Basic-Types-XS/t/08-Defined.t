use Test::More;

use Basic::Types::XS qw/Defined/;

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

is(Defined->($str), "abc");
is(Defined->($num), 123);
is(Defined->($num2), 123);
is(Defined->($d), 123.123);
is(Defined->($d2), 123.123);
is(Defined->($invalid), "123.123.456");
is_deeply(Defined->($hash), { a => 1 });
is_deeply(Defined->($array), [qw/1 2 3/]);
is_deeply(Defined->($blessed), { a => 1 });
ok(Defined->($sub));
is_deeply(Defined->($ref), \1);
is_deeply(Defined->($blessed_ref), \"abc");

eval {
	Defined->(undef);
};

like($@, qr/value did not pass type constraint "Defined"/);


ok(1);

done_testing();
