
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Beam::Wire;

subtest 'compose a single role' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                with => 'My::ArgsListRole',
                args => {
                    foo => 'bar',
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::ArgsTest';
    ok $svc->DOES( 'My::ArgsListRole' );
    cmp_deeply [ $svc->got_args_list ], [ foo => 'bar' ];
};

subtest 'compose multiple roles' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                with => [
                    'My::ArgsListRole',
                    'My::CloneRole',
                ],
                args => {
                    foo => 'bar',
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::ArgsTest';
    ok $svc->DOES( 'My::ArgsListRole' );
    ok $svc->DOES( 'My::CloneRole' );
    cmp_deeply [ $svc->got_args_list ], [ foo => 'bar' ];
    ok $svc->can( 'clone' );
};
done_testing;
