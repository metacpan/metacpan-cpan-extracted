use Test::More;

use Basic::Types::XS qw/ClassName/;

{
	package Okay;

	1;
}

is(ClassName()->('Okay'), 'Okay');

my $thing = bless {}, 'Foo';
my $arr = bless {}, 'Arr';
my $s = 1;
my $scalar = bless \$s, 'Sca';
use Data::Dumper;
is(ClassName()->('Foo'), 'Foo');
is(ClassName()->('Arr'), 'Arr');
is(ClassName()->('Sca'), 'Sca');

my $str = "abc";
my $num = 123;
my $num2 = "123";
my $d = 123.123;
my $d2 = "123.123";
my $invalid = "123.123.456";
my $hash = { a => 1 };
my $blessed = bless [qw/1 2 3/], 'Foo';
my $sub = sub { return 2 };


is_deeply(ClassName->('Foo'), 'Foo');

eval {
	ClassName->($blessed);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($num);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($num2);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($d);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($d2);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($str);
};

like($@, qr/value did not pass type constraint "ClassName"/);

eval {
	ClassName->($invalid);
};

like($@, qr/value did not pass type constraint "ClassName"/);


ok(1);

done_testing();
