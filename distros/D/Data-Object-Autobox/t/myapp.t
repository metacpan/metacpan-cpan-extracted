use Test::More;

use lib 't/lib';

use_ok 'MyApp::Autobox::Number';
use_ok 'MyApp::Autobox::Scalar';
use_ok 'MyApp::Autobox::Hash';
use_ok 'MyApp::Autobox::Array';
use_ok 'MyApp::Autobox::String';
use_ok 'MyApp::Autobox::Integer';
use_ok 'MyApp::Autobox::Universal';
use_ok 'MyApp::Autobox::Float';
use_ok 'MyApp::Autobox::Code';
use_ok 'MyApp::Autobox::Undef';

use Data::Object::Autobox -custom => (
    ARRAY     => "MyApp::Autobox::Array",
    CODE      => "MyApp::Autobox::Code",
    FLOAT     => "MyApp::Autobox::Float",
    HASH      => "MyApp::Autobox::Hash",
    INTEGER   => "MyApp::Autobox::Integer",
    NUMBER    => "MyApp::Autobox::Number",
    SCALAR    => "MyApp::Autobox::Scalar",
    STRING    => "MyApp::Autobox::String",
    UNDEF     => "MyApp::Autobox::Undef",
    UNIVERSAL => "MyApp::Autobox::Universal",
);

subtest 'test custom MyApp::Autobox classes' => sub {
    my $num = 1;
    ok $num->autobox_class->isa('MyApp::Autobox::Number');
    is $num->custom, 'MyApp::Autobox::Integer';
    my $zero = 000;
    ok $zero->autobox_class->isa('MyApp::Autobox::Scalar');
    is $zero->custom, 'MyApp::Autobox::Integer';
    my $hash = {};
    ok $hash->autobox_class->isa('MyApp::Autobox::Hash');
    is $hash->custom, 'MyApp::Autobox::Hash';
    my $array = [];
    ok $array->autobox_class->isa('MyApp::Autobox::Array');
    is $array->custom, 'MyApp::Autobox::Array';
    my $string = "abc";
    ok $string->autobox_class->isa('MyApp::Autobox::String');
    is $string->custom, 'MyApp::Autobox::String';
    my $int = 1;
    ok $int->autobox_class->isa('MyApp::Autobox::Integer');
    is $int->custom, 'MyApp::Autobox::Integer';
    my $any = _;
    ok $any->autobox_class->isa('MyApp::Autobox::Universal');
    is $any->custom, 'MyApp::Autobox::String';
    my $float = 1.23;
    ok $float->autobox_class->isa('MyApp::Autobox::Float');
    is $float->custom, 'MyApp::Autobox::Float';
    my $code = sub{};
    ok $code->autobox_class->isa('MyApp::Autobox::Code');
    is $code->custom, 'MyApp::Autobox::Code';
    my $undef = undef;
    ok $undef->autobox_class->isa('MyApp::Autobox::Undef');
    is $undef->custom, 'MyApp::Autobox::Undef';
};

ok 1 and done_testing;
