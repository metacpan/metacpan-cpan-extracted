
use Test::More;
use Test::Exception;
use Test::Lib;
use Scalar::Util qw( refaddr );
use Beam::Wire;

subtest 'env service' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => {
                '$env' => 'GREETING'
            }
        },
    );

    local $ENV{GREETING} = 'Hello, World';
    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    is $greeting, $ENV{GREETING};
};

subtest 'default value' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => {
                '$env' => 'GREETING',
                '$default' => 'DEFAULT',
            }
        },
    );

    local %ENV = %ENV;
    delete $ENV{GREETING};
    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    is $greeting, 'DEFAULT';
};

done_testing;
