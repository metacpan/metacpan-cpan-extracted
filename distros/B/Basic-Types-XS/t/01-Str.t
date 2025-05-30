use Test::More;
use strict;
use warnings;
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

my $string = Str(
	message => "This is a custom error message",
	coerce => sub {
		my $value = shift;
		return join ",", @{$value} if ref $value eq "ARRAY";
		return $value;
	},
	default => sub {
		return "default value";
	},
);

is($string->("abc"), "abc");
is($string->(undef), "default value");
is($string->([qw/a b c/]), "a,b,c");
eval {
	$string->({});
};

like($@, qr/This is a custom error message/);


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
