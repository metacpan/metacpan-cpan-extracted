
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Beam::Wire;

subtest 'compose a single role' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ClassTest',
                with => 'My::AttrRole',
                args => {
                    foo => 'bar',
                    attr => 'pelican',
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::ClassTest';
    ok $svc->DOES( 'My::AttrRole' );
    cmp_deeply [ $svc->foo ], [ 'bar' ];
    cmp_deeply [ $svc->attr ], [ 'pelican' ];
};

subtest 'compose multiple roles' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ClassTest',
                with => [
                    'My::AttrRole',
                    'My::CloneRole',
                ],
                args => {
                    foo => 'bar',
                    attr => 'sheep',
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::ClassTest';
    ok $svc->DOES( 'My::AttrRole' );
    ok $svc->DOES( 'My::CloneRole' );
    cmp_deeply [ $svc->foo ], [ 'bar' ];
    cmp_deeply [ $svc->attr ], [ 'sheep' ];
    ok $svc->can( 'clone' );
};
done_testing;
