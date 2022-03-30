use strict;
use warnings;
use Test::More tests => 3;

use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Processor;
use Data::FormValidator;

package Validator {
    use Moo;
    use Data::FormValidator::Constraints qw(:closures);

    with 'Dancer2::Plugin::FormValidator::Role::HasProfileMessages';

    sub profile {
        return {
            required => [qw(name email)],
            constraint_methods => {
                email => email,
            },
        };
    };

    sub messages {
        return 'Error occurred';
    }
}

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session  => {
            namespace => '_form_validator'
        },
    },
);

my $validator = Validator->new;
my $result;
my $results;
my $processor;

# TEST 1.
## Check messages string.

$results = Data::FormValidator->check(
    {
        email => 'alexpan@cpan.org',
    },
    $validator->profile,
);

$processor = Dancer2::Plugin::FormValidator::Processor->new(
    config    => $config,
    validator => $validator,
    results   => $results,
);

$result = $processor->result;

is($result->messages, 'Error occurred', 'TEST 1: Check messages string');

# TEST 2.
## Check messages hash.

package Validator2 {
    use Moo;
    use Data::FormValidator::Constraints qw(:closures);

    with 'Dancer2::Plugin::FormValidator::Role::HasProfileMessages';

    sub profile {
        return {
            required => [qw(name email)],
            constraint_methods => {
                email => email,
            },
        };
    };

    sub messages {
        return {
            'email' => '%s should be a valid email.',
        };
    }
}

$validator = Validator2->new;

$results = Data::FormValidator->check(
    {
        email => 'alexpan.org',
    },
    $validator->profile,
);

$processor = Dancer2::Plugin::FormValidator::Processor->new(
    config    => $config,
    validator => $validator,
    results   => $results,
);

$result = $processor->result;

is_deeply(
    $result->messages,
    {
        'name'  => 'Name is missing.',
        'email' => 'Email should be a valid email.'
    },
    'TEST 2: Check messages hash'
);

# TEST 3.
## Check default missing message hash.

package Validator3 {
    use Moo;
    use Data::FormValidator::Constraints qw(:closures);

    with 'Dancer2::Plugin::FormValidator::Role::HasProfile';

    sub profile {
        return {
            required => [qw(name email)],
            constraint_methods => {
                email => email,
            },
        };
    };
}

$validator = Validator3->new;

$results = Data::FormValidator->check(
    {
        email => 'alexpan.org',
    },
    $validator->profile,
);

$processor = Dancer2::Plugin::FormValidator::Processor->new(
    config    => $config,
    validator => $validator,
    results   => $results,
);

$result = $processor->result;

is_deeply(
    $result->messages,
    {
        'name'  => 'Name is missing.',
        'email' => 'Email is invalid.'
    },
    'TEST 3: Check default missing message hash'
);
