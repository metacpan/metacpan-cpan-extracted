use Test::More;
use Colouring::In {
	VALIDATE_ERROR => 'validation error',
	VALIDATE => 'validation success'
};

close(STDERR);

my $validate1 = Colouring::In->validate([0, 0, 0], 'a');

is_deeply(${$validate1->{valid}}, 1);
is($validate1->{colour}->toRGB, 'rgb(0,0,0)');

my $invalid = Colouring::In->validate('#xyz', 'a');

is_deeply(${$invalid->{valid}}, 0);

$invalid = Colouring::In->validate('rgb(xyz, xyz, xyz)', 'a');

is_deeply(${$invalid->{valid}}, 0);

$invalid = Colouring::In->validate('hsl(xyz, xyz, xyz)', 'a');

is_deeply(${$invalid->{valid}}, 0);

done_testing();
