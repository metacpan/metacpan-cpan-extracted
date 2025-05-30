use Test::More;

use Basic::Types::XS qw/Object/;

my $thing = bless {}, 'Foo';
my $arr = bless {}, 'Foo';
my $s = 1;
my $scalar = bless \$s, 'Foo';
use Data::Dumper;
is(Object()->($thing), $thing);
is(Object()->($arr), $arr);
is(Object()->($scalar), $scalar);

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $blessed = bless [qw/1 2 3/], 'Foo';
my $sub = sub { return 2 };


is_deeply(Object->($blessed), [qw/1 2 3/]);

eval {
	Object->($num);
};

like($@, qr/value did not pass type constraint "Object"/);

eval {
	Object->($num2);
};

like($@, qr/value did not pass type constraint "Object"/);

eval {
	Object->($d);
};

like($@, qr/value did not pass type constraint "Object"/);

eval {
	Object->($d2);
};

like($@, qr/value did not pass type constraint "Object"/);

eval {
	Object->($str);
};

like($@, qr/value did not pass type constraint "Object"/);

eval {
	Object->($invalid);
};

like($@, qr/value did not pass type constraint "Object"/);


ok(1);

done_testing();
