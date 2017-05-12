
use Test::More;
use Test::Exception;
use Test::Lib;
use Test::Deep;
use Beam::Wire;

subtest 'path reference' => sub {
    # XXX: Deprecate this for $value => $path
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::RefTest',
                args  => {
                    got_ref => {
                        '$ref'  => 'config',
                        '$path' => '//en/greeting'
                    }
                },
            },
            config => {
                value => {
                    en => {
                        greeting => 'Hello, World'
                    }
                }
            }
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    isa_ok $foo, 'My::RefTest';
    is $foo->got_ref, 'Hello, World' or diag explain $foo->got_ref;
};

done_testing;
