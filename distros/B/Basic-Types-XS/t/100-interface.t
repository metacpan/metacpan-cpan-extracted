use Test::More;

use Basic::Types::XS qw/Str/;


my $string = Str->message("Hello, World!")->default(sub { 200 })->coerce(sub { ref $_[0] ? $_[0] : $_[0] . "!" });

is($string->(undef), "200!", "Default value is used when no argument is provided");
is($string->(()), "200!", "Default value is used when no argument is provided");

eval {
	$string->({});
};
like($@, qr/Hello, World!/);

$string->message("Goodbye, World!");

eval {
	$string->([]);
};
like($@, qr/Goodbye, World!/);

eval {
	Str->Hash;
};
like($@, qr/Can't locate object method "Hash"/);

done_testing
