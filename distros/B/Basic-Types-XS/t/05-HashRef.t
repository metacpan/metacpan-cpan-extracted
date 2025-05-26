use Test::More;

use Basic::Types::XS qw/HashRef/;

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


is_deeply(HashRef->($hash), { a => 1 });
is_deeply(HashRef->($blessed), { a => 1 });

eval {
	HashRef->($num);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($num2);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($d);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($d2);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($str);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($invalid);
};

like($@, qr/value did not pass type constraint "HashRef"/);



eval {
	HashRef->(undef);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($array);
};

like($@, qr/value did not pass type constraint "HashRef"/);

eval {
	HashRef->($sub);
};

like($@, qr/value did not pass type constraint "HashRef"/);


ok(1);

done_testing();
