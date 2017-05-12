use strict;
use warnings FATAL => 'all';
use Test::More;
use ConditionSystem;
use Try::Tiny;

{
    package MalformedLogEntry;
    use Moose;
    extends 'Throwable::Error';

    has bad_data => ( is => 'ro' );
};

{
    package InsufficientMoose;
    use Moose;
    extends 'Throwable::Error';
};

{
    package ENOBEER;
    use Moose;
    extends 'Throwable::Error';
};

subtest 'handler_case' => sub {
    my ($not_here, $here);
    with_handlers {
        InsufficientMoose->throw('Your Moose skills are weak old man');
    }
    handle(InsufficientMoose => sub {
        $here = 1
    }),
    handle(ENOBEER => sub {
        $not_here = 1;
    });

    ok($here, 'Handled the correct exception');
    ok(!$not_here, 'Did not handle other (unmatched) exceptions');
};

subtest 'handler_case + Try::Tiny' => sub {
    my $here;
    with_handlers {
        InsufficientMoose->throw('Your Moose skills are weak old man');
    }
    handle InsufficientMoose => catch {
        $here = 1;
    };

    ok($here, 'All is good in Try::Tiny land');
};

subtest 'restarts' => sub {
    my ($started, $restarted, $invoked_restart, $restart_value);

    my $risky_business = sub {
        restart_case {
            ENOBEER->new('How the hell am I meant to code now?')
        }
        bind_continue(use_me => sub {
            $invoked_restart++;
            return shift;
        }),
        bind_continue(shy_restart_case => sub {
            die 'Should not be called'
        });
    };

    with_handlers {
        $started = 1;
        $restart_value = $risky_business->();
        $restarted = 1;
    }
    handle(ENOBEER => restart('use_me', 'A strong beverage'));

    ok($started, 'started the code block');
    ok($restarted, 'did eventually past exception');
    is($invoked_restart => 1, 'invoked the correct restart once');
    is($restart_value => 'A strong beverage',
       'Correctly returned');3
};

done_testing;
