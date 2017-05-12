
use Test::More;
use Test::Exception;
use Test::Lib;
use Beam::Wire;

subtest '2.0' => sub {

    subtest '$method in event handler (2015-03-08)' => sub {
        # $method is ambiguous with the $class
        my @warnings;
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
        };

        my $wire = Beam::Wire->new(
            config => {
                emitter => {
                    class => 'My::Emitter',
                    lifecycle => 'factory',
                    on => {
                        greet => {
                            '$class' => 'My::Listener',
                            '$method' => 'on_greet',
                        },
                    },
                },
            },
        );

        subtest 'still works even though deprecated' => sub {
            my $svc;
            lives_ok { $svc = $wire->get( 'emitter' ) };
            isa_ok $svc, 'My::Emitter';

            $svc->emit( 'greet' );
            is $My::Listener::LAST_CREATED->events_seen, 1;
        };

        is scalar @warnings, 1;
        is $warnings[0], qq{warning: (deprecated) "\$method" in event handlers is now "\$sub" in service "emitter"\n};

        subtest 'only one warning is emitted per problem' => sub {
            $wire->get( 'emitter' );
            is @warnings, 1;
        };

    };

};

done_testing;
