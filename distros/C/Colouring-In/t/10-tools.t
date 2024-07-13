use Test::More;

use Colouring::In;

my %TOOL = %Colouring::In::TOOL;

##################
#     CLAMP     #
#################
run_test('clamp', 1, 1, 2);
run_test('clamp', 1, 2, 1);
run_test('clamp', 0, 0, 0);
run_test('clamp', 0, undef, undef);

#################
#      MIN      #
#################
run_test('min', 1, 1, 2);
run_test('min', 1, 2, 1);
run_test('min', 0, 0, 0);
run_test('min', 0, undef, undef);
run_test('min', -2, -1, -2); # this is not necessarily wrong in the context it's being called.

#################
#      MAX      #
#################
run_test('max', 2, 1, 2);
run_test('max', 2, 2, 1);
run_test('max', 0, 0, 0);
run_test('max', 0, undef, undef);
run_test('max', -1, -1, -2); # same here although we call clamp internally as 0 is the lowest css can go.

#################
#     Darken    #
#################
run_test('round', 10, 10.23, undef);
run_test('round', 10.23, 10.23, 2);

#################
#     HUE    #
#################
run_test('hue', 1, 1.9, 1, 1);
run_test('hue', 0.23, 0.67, 0.23, 0);

#################
#     scaled    #
#################
run_test('scaled', '10', '10%', 100);
run_test('scaled', '10', 10, 100);


#######################
#     converColour    #
#######################
eval{
	run_test('convertColour', 0, 'not(0,0,0)');
};
like($@, qr/Cannot convert the colour format/);

#######################
#     hex2rgb	      #
#######################
eval{
	run_test('hex2rgb', 0, '0000');
};

like($@, qr/hex length must be 3 or 6/);


sub run_test {
	my ($method, $expect, @params) = @_;
	is($TOOL{$method}->(@params), $expect, $method);
}

done_testing();

