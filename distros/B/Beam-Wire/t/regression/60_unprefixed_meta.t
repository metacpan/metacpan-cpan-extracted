
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Lib;
use Test::Exception;
use Beam::Wire;

# Unprefixed meta data must only be allowed in the root, not in args or
# deep in data structures
#
# https://github.com/preaction/Beam-Wire/issues/60

my $wire = Beam::Wire->new(
    config => {
        foo => {
            class => 'My::ArgsTest',
            args => {
                path => '/foo/bar/baz',
                value => 'value',
            },
        },
    },
);

my $obj;
lives_ok { $obj = $wire->get( 'foo' ) } 'can get object with args that look like unprefixed meta';
cmp_deeply
    $obj->got_args_hash,
    { path => '/foo/bar/baz', value => 'value' },
    'args that look like unprefixed meta are not processed';

done_testing;
