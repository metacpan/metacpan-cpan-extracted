use Test::More;

my $deep = { okay => 1 };
my $deeper = { okay => 2 };

$deep->{deeper} = $deeper;
$deep->{deep} = $deep;

$deeper->{deep} = $deep;

use Const::XS qw/all/;

ok(1);

make_readonly($deeper);

is(is_readonly($deeper), 1);

eval {
	$deeper->{deep}->{deep} = 2;

};

like($@, qr/Modification of a read-only value/);

unmake_readonly($deeper);

ok($deeper->{deep}->{deep} = 2);

is($deeper->{deep}->{deep}, 2);

my $i = 0;
my (%keys) = (
	map { $_ => $i++ } a..z
);

my $hash = {%keys};
my $copy = $hash;
for (1..999) {
	$copy->{a} = {%keys};
	$copy = $copy->{a};
}

make_readonly($hash);
is(is_readonly($hash), 1);

my $obj = bless { a => 1 }, 'Imaginary';

make_readonly($obj);
is(is_readonly($obj), 1);

eval {
	$obj->{b} = 2;
};

like($@, qr/Attempt to access disallowed key 'b' in a restricted hash/);

done_testing();
