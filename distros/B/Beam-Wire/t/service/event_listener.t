
use Test::More;
use Test::Exception;
use Test::Lib;
use Beam::Wire;
use My::Listener;

subtest 'single event listener' => sub {
    my $wire = Beam::Wire->new(
        config => {
            emitter => {
                class => 'My::Emitter',
                on => {
                    greet => {
                        '$ref' => 'listener',
                        '$sub' => 'on_greet',
                    },
                },
            },
            listener => {
                class => 'My::Listener',
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'emitter' ) };
    isa_ok $svc, 'My::Emitter';

    $svc->emit( 'greet' );
    is $wire->get( 'listener' )->events_seen, 1;
};

subtest 'multiple event listeners' => sub {

    subtest 'hash of arrays, the logical way, that we will keep' => sub {
        my $wire = Beam::Wire->new(
            config => {
                emitter => {
                    class => 'My::Emitter',
                    on => {
                        greet => [
                            {
                                '$ref' => 'listener',
                                '$sub' => 'on_greet',
                            },
                            {
                                '$ref' => 'other_listener',
                                '$sub' => 'on_greet',
                            },
                        ],
                    },
                },
                listener => {
                    class => 'My::Listener',
                },
                other_listener => {
                    class => 'My::Listener',
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'emitter' ) };
        isa_ok $svc, 'My::Emitter';

        $svc->emit( 'greet' );
        is $wire->get( 'listener' )->events_seen, 1;
        is $wire->get( 'other_listener' )->events_seen, 1;
    };

    subtest 'array of hashes, less logical, to get around a YAML.pm bug' => sub {
        my $wire = Beam::Wire->new(
            config => {
                emitter => {
                    class => 'My::Emitter',
                    on => [
                        {
                            greet => {
                                '$ref' => 'listener',
                                '$sub' => 'on_greet',
                            },
                        },
                        {
                            greet => {
                                '$ref' => 'other_listener',
                                '$sub' => 'on_greet',
                            },
                        },
                    ],
                },
                listener => {
                    class => 'My::Listener',
                },
                other_listener => {
                    class => 'My::Listener',
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'emitter' ) };
        isa_ok $svc, 'My::Emitter';

        $svc->emit( 'greet' );
        is $wire->get( 'listener' )->events_seen, 1;
        is $wire->get( 'other_listener' )->events_seen, 1;

    };

};

subtest 'anonymous listeners' => sub {

    subtest '$class' => sub {
        my $wire = Beam::Wire->new(
            config => {
                emitter => {
                    class => 'My::Emitter',
                    on => {
                        greet => {
                            '$class' => 'My::Listener',
                            '$args' => {
                                attribute => 'foo',
                            },
                            '$sub' => 'on_greet',
                        },
                    },
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'emitter' ) };
        isa_ok $svc, 'My::Emitter';

        $svc->emit( 'greet' );
        is $My::Listener::LAST_CREATED->events_seen, 1;
        is $My::Listener::LAST_CREATED->attribute, 'foo';
    };

    subtest '$extends' => sub {
        my $wire = Beam::Wire->new(
            config => {
                emitter => {
                    class => 'My::Emitter',
                    on => {
                        greet => {
                            '$extends' => 'listener',
                            '$sub' => 'on_greet',
                        },
                    },
                },
                listener => {
                    class => 'My::Listener',
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'emitter' ) };
        isa_ok $svc, 'My::Emitter';

        $svc->emit( 'greet' );
        is $My::Listener::LAST_CREATED->events_seen, 1;
    };

};


done_testing;
