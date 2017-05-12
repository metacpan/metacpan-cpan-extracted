use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Number', 'abs';
subtest 'test the abs method' => sub {
    my $number = 12;
    is 12, $number->abs; # 12

    $number = -12;
    is 12, $number->abs; # 12
};

can_ok 'Bubblegum::Object::Number', 'atan2';
subtest 'test the atan2 method' => sub {
    my $number = 1;
    like $number->atan2(1), qr/^0.78539/; # 0.785398163397448
};

can_ok 'Bubblegum::Object::Number', 'cos';
subtest 'test the cos method' => sub {
    my $number = 12;
    like $number->cos, qr/^0.84385/; # 0.843853958732492
};

can_ok 'Bubblegum::Object::Number', 'decr';
subtest 'test the decr method' => sub {
    my $number = 123456789;
    is 123456788, $number->decr; # 123456788
};

can_ok 'Bubblegum::Object::Number', 'exp';
subtest 'test the exp method' => sub {
    my $number = 0;
    is 1, $number->exp; # 1

    $number = 1;
    like $number->exp, qr/^2.71828/; # 2.71828182845905

    $number = 1.5;
    like $number->exp, qr/^4.48168/; # 4.48168907033806
};

can_ok 'Bubblegum::Object::Number', 'hex';
subtest 'test the hex method' => sub {
    my $number = 175;
    is '0xaf', $number->hex; # 0xaf
};

can_ok 'Bubblegum::Object::Number', 'incr';
subtest 'test the incr method' => sub {
    my $number = 123456789;
    is 123456790, $number->incr; # 123456790
};

can_ok 'Bubblegum::Object::Number', 'int';
subtest 'test the int method' => sub {
    my $number = 12.5;
    is 12, $number->int; # 12
};

can_ok 'Bubblegum::Object::Number', 'log';
subtest 'test the log method' => sub {
    my $number = 12345;
    like $number->log, qr/^9.42100/; # 9.42100640177928
};

can_ok 'Bubblegum::Object::Number', 'mod';
subtest 'test the mod method' => sub {
    my $number = 12;
    is 0, $number->mod(1); # 0
    is 0, $number->mod(2); # 0
    is 0, $number->mod(3); # 0
    is 0, $number->mod(4); # 0
    is 2, $number->mod(5); # 2
};

can_ok 'Bubblegum::Object::Number', 'neg';
subtest 'test the neg method' => sub {
    my $number = 12345;
    is -12345, $number->neg; # -12345
};

can_ok 'Bubblegum::Object::Number', 'pow';
subtest 'test the pow method' => sub {
    my $number = 12345;
    is 1881365963625, $number->pow(3); # 1881365963625
};

can_ok 'Bubblegum::Object::Number', 'sin';
subtest 'test the sin method' => sub {
    my $number = 12345;
    like $number->sin, qr/^-0.99377/; # -0.993771636455681
};

can_ok 'Bubblegum::Object::Number', 'sqrt';
subtest 'test the sqrt method' => sub {
    my $number = 12345;
    like $number->sqrt, qr/^111.10805/; # 111.108055513541
};

can_ok 'Bubblegum::Object::Number', 'to_array';
subtest 'test the to_array method' => sub {
    my $int = 1;
    is_deeply $int->to_array, [1]; # [1]
};

can_ok 'Bubblegum::Object::Number', 'to_code';
subtest 'test the to_code method' => sub {
    my $int = 1;
    is 'CODE', ref $int->to_code; # sub { 1 }
    is 1, $int->to_code->();
};

can_ok 'Bubblegum::Object::Number', 'to_hash';
subtest 'test the to_hash method' => sub {
    my $int = 1;
    is_deeply $int->to_hash, { 1 => 1 }; # { 1 => 1 }
};

can_ok 'Bubblegum::Object::Number', 'to_number';
subtest 'test the to_number method' => sub {
    my $int = 1;
    is 1, $int->to_number; # 1
};

can_ok 'Bubblegum::Object::Number', 'to_string';
subtest 'test the to_string method' => sub {
    my $int = 1;
    is '1', $int->to_string; # '1'
};

done_testing;
