use Test::More;
use Colouring::In::XS {
	VALIDATE_ERROR => 'validation error',
	VALIDATE => 'validation success'
};

close(STDERR);

my $validate1 = Colouring::In::XS->validate([0, 0, 0], 'a');

is_deeply(${$validate1->{valid}}, 1);
is($validate1->{colour}->toRGB, 'rgb(0,0,0)');

my $invalid = Colouring::In::XS->validate('#xyz', 'a');

is_deeply(${$invalid->{valid}}, 0);

$invalid = Colouring::In::XS->validate('rgb(xyz, xyz, xyz)', 'a');

is_deeply(${$invalid->{valid}}, 0);

$invalid = Colouring::In::XS->validate('hsl(xyz, xyz, xyz)', 'a');

is_deeply(${$invalid->{valid}}, 0);

done_testing();
