use Test::More;

use Basic::Types::XS qw/Any/;

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

is(Any->($str), "abc");
is(Any->($num), 123);
is(Any->($num2), 123);
is(Any->($d), 123.123);
is(Any->($d2), 123.123);
is(Any->($invalid), "123.123.456");
is_deeply(Any->($hash), { a => 1 });
is_deeply(Any->($array), [qw/1 2 3/]);
is_deeply(Any->($blessed), { a => 1 });
ok(Any->($sub));
is_deeply(Any->($ref), \1);
is_deeply(Any->($blessed_ref), \"abc");
is(Any->(undef), undef);
eval {
	Any->();
};

like($@, qr/value did not pass type constraint "Any"/);


ok(1);

done_testing();
