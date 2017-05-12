use strict;
use warnings;

package App::Rssfilter::FromYaml::Test::DelegatesToFromHash;

use Test::Routine;
use Test::Exception;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'fake_from_hash';

test delegates_to_from_hash => method {
    $self->from_yaml(<<"end");
    hi: hello
    asd:
    - a
    - s
    - d
end

    my ($name, $args) = $self->fake_from_hash->next_call;
    is(
        $name,
        'from_hash',
        'from_yaml called from_hash ...'
    );
    is_deeply(
        $args->[1],
        { hi => 'hello', asd => [ qw< a s d > ], },
        '... with the YAML as a hash'
    );

};

1;
