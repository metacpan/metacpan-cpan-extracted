use Test::More;
BEGIN {
    eval q{ use Test::Dependencies };
    plan skip_all => "Test::Dependencies is not installed." if $@;
}

use Test::Dependencies
    exclude => [qw/Test::Dependencies App::Donburi/],
    style   => 'light' ;

ok_dependencies();

