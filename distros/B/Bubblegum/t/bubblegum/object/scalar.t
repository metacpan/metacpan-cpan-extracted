use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Scalar', 'and';
subtest 'test the and method' => sub {
    my $variable = 12345;
    is 56789, $variable->and(56789); # 56789
    $variable = 0;
    is 0, $variable->and(56789); # 0
};

can_ok 'Bubblegum::Object::Scalar', 'not';
subtest 'test the not method' => sub {
    my $variable = 0;
    is 1, $variable->not; # 1

    $variable = 1;
    is '', $variable->not; # ''
};

can_ok 'Bubblegum::Object::Scalar', 'or';
subtest 'test the or method' => sub {
    my $variable = 12345;
    is 12345, $variable->or(56789); # 12345

    $variable = 00000;
    is 56789, $variable->or(56789); # 56789
};

can_ok 'Bubblegum::Object::Scalar', 'print';
subtest 'test the print method' => sub {
    my $variable = '';
    is 1, $variable->print; # ''
    is 1, $variable->print(''); # ''
};

can_ok 'Bubblegum::Object::Scalar', 'repeat';
subtest 'test the repeat method' => sub {
    my $variable = 12345;
    is 1234512345, $variable->repeat(2); # 1234512345
    $variable = 'yes';
    is 'yesyes', $variable->repeat(2); # yesyes
};

can_ok 'Bubblegum::Object::Scalar', 'say';
subtest 'test the say method' => sub {
    my $variable = '';
    is 1, $variable->say; # ''
    is 1, $variable->say(''); # ''
};

can_ok 'Bubblegum::Object::Scalar', 'xor';
subtest 'test the xor method' => sub {
    my $variable = 1;
    is 0, $variable->xor(1); # 0
    is 1, $variable->xor(0); # 1
};

done_testing;
