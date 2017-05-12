
use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Deep;
use Test::Exception;
use Beam::Wire;

my $wire = Beam::Wire->new(
    config => {
        base_class => {
            class => 'My::ArgsTest',
        },
        base_no_class => { },
    },
);

my $svc;

lives_ok { $svc = $wire->create_service( 'testing', class => 'My::ArgsTest' ) }
    'create service with class only';
cmp_deeply $svc->got_args, [], 'no args given';

throws_ok { $svc = $wire->create_service( 'testing', path => '/foo/bar' ) }
    'Beam::Wire::Exception::InvalidConfig',
    'must have one of "class", "value", "config" in the merged config';

throws_ok { $svc = $wire->create_service( 'testing', extends => 'base_no_class' ) }
    'Beam::Wire::Exception::InvalidConfig',
    'merged config from extends must have one of "class", "value", "config" in the merged config';

throws_ok { $svc = $wire->create_service( 'testing', class => 'My::ArgsTest', value => '' ) }
    'Beam::Wire::Exception::InvalidConfig',
    'cannot use "value" with "class"';
throws_ok { $svc = $wire->create_service( 'testing', extends => 'base_class', value => '' ) }
    'Beam::Wire::Exception::InvalidConfig',
    'cannot use "value" with "extends"';

done_testing;
