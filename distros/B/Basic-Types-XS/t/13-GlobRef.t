use Test::More;

use Basic::Types::XS qw/GlobRef/;

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

open my $fh, '>', 'test.txt';

is(GlobRef->($fh), $fh);

close $fh;

eval {
	GlobRef->($num);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($num2);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($d);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($d2);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($str);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($invalid);
};

like($@, qr/value did not pass type constraint "GlobRef"/);


eval {
	GlobRef->(undef);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($hash);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($array);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($blessed);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($sub);
};

like($@, qr/value did not pass type constraint "GlobRef"/);

eval {
	GlobRef->($reg);
};

like($@, qr/value did not pass type constraint "GlobRef"/);


ok(1);

done_testing();
