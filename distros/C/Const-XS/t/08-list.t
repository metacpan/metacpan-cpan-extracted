use Const::XS qw/all/;
use Test::More;

my %hash = (a =>1, b =>2, c=>3);

make_readonly(%hash);

eval { $hash{d} = 4; };

like ($@, qr/Attempt to access disallowed key 'd' in a restricted hash/);

is(is_readonly(%hash), 1);

unmake_readonly(%hash);

$hash{d} = 4;

is(is_readonly(%hash), 0);

is($hash{d}, 4);

my @array = qw/a b c/;

make_readonly(@array);

eval { push @array, 'd' };

is_deeply(\@array, [qw/a b c/]);

is(is_readonly(@array), 1);

unmake_readonly(@array);

push @array, 'd';

is_deeply(\@array, [qw/a b c d/]);

ok(1);

done_testing();
