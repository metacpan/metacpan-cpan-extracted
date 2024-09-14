
use Test::More;
use Test::Exception;
use Test::Lib;
use Scalar::Util qw( refaddr );
use Beam::Wire;

package TestClass {
    sub new { return bless {}, $_[0] }
    sub greeting { return 'Hello, World' }
}
$INC{'TestClass.pm'} = 'TestClass.pm';    # so module looks like it's been loaded.


subtest 'ref service: $call' => sub {
    my $wire = Beam::Wire->new(
        config => {
            klass => {
               '$class' => 'TestClass',
            },
            greeting => {
                '$ref' => 'klass',
                '$call' => 'greeting',
            }
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    ok !ref $greeting, 'got a simple scalar';
    is $greeting, 'Hello, World';
};

subtest 'ref service: $path' => sub {
    my $wire = Beam::Wire->new(
        config => {
            subcfg => {
               greeting => 'Hello, World'
            },
            greeting => {
                '$ref' => 'subcfg',
                '$path' => '/greeting',
            }
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    ok !ref $greeting, 'got a simple scalar';
    is $greeting, 'Hello, World';
};


done_testing;
