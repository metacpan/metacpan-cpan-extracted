use Const::XS qw/all/;
use Test::More;
const my $foo => 'a scalar value';
const my $buz => 'another value';
const my @bar => qw/a list value/, { hash => 1, deep => { one => 'nope' } }, [ 'nested', { hash => 2 } ];
const my @merge => ($foo, $buz);
const my @copy => @merge;
const my @refs => @bar;
const my %hash => (
	one => 1
);
const my %hash2 => (
	%hash,
	two => 2
);
const my %hash3 => (
	%hash2,
	three => 3
);
const my $ref => {
	ref => \%hash,
	test => $foo,
	%hash3
};

const my @deeep => (
	{ one => qr/abc/, cb => sub { 111 } }
);

is_deeply(\@merge, ['a scalar value', 'another value']);
is_deeply(\@copy, ['a scalar value', 'another value']);
is_deeply(\@bar, [qw/a list value/, { hash => 1, deep => { one => 'nope' } }, [ 'nested', { hash => 2 } ] ]);
is_deeply(\@refs, [qw/a list value/, { hash => 1, deep => { one => 'nope' } }, [ 'nested', { hash => 2 } ] ]);

eval { $refs[0] = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { @refs = qw/1 2 3/ };

like($@, qr/Modification of a read-only value attempted/); 

eval { $refs[3]->{hash} = 2 };

like($@, qr/Modification of a read-only value attempted/); 

eval { push @refs, 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

is_deeply(\%hash3, { one => 1, two => 2, three => 3 });

eval { delete $hash3{one} };

like($@, qr/Attempt to delete readonly key 'one' from a restricted hash/); 

eval { $hash{four} = 4; };

like($@, qr/Attempt to access disallowed key 'four' in a restricted hash/); 

is_deeply($ref, { test => 'a scalar value',  one => 1, two => 2, three => 3, ref => { one => 1 } });

eval { $ref->{four} = 4; };

like($@, qr/Attempt to access disallowed key 'four' in a restricted hash/); 

eval { $ref->{ref}->{four} = 4; };

like($@, qr/Attempt to access disallowed key 'four' in a restricted hash/); 




done_testing();
