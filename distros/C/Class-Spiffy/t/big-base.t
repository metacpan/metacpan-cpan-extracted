use Test::More tests => 1;

eval q{
    package Foo;
    use Class::Spiffy -Base;
};

like $@, qr{^\QUse of '-Base' with Class::Spiffy is illegal},
    "Class::Spiffy users can't use -Base";
