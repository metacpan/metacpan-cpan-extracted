
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Beam::Wire;

subtest '2.0' => sub {

    subtest 'method in dependency (2015-03-29)' => sub {
        # $method is ambiguous with service creation ($class)
        my @warnings;
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
        };

        my $wire = Beam::Wire->new(
            config => {
                foo => {
                    class => 'My::RefTest',
                    args  => {
                        got_ref => {
                            '$ref' => 'greeting',
                            '$method' => 'got_args_hash',
                        },
                    },
                },
                greeting => {
                    class => 'My::ArgsTest',
                    args => {
                        hello => "Hello",
                        default => 'World',
                    },
                },
            },
        );

        subtest 'still works even though deprecated' => sub {
            my $svc;
            lives_ok { $svc = $wire->get( 'foo' ) };
            isa_ok $svc, 'My::RefTest';
            cmp_deeply $svc->got_ref, { hello => 'Hello', default => 'World' }
                or diag explain $svc->got_ref;
        };

        is scalar @warnings, 1;
        is $warnings[0], qq{warning: (deprecated) Using "\$method" to get a value in a dependency is now "\$call" in service "foo"\n};

        subtest 'only one warning is emitted per problem' => sub {
            $wire->get( 'foo' );
            is @warnings, 1;
        };

    };

    subtest 'method with one argument (2015-03-29)' => sub {
        # $method is ambiguous with service creation ($class)
        my @warnings;
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
        };

        my $wire = Beam::Wire->new(
            config => {
                foo2 => {
                    class => 'My::RefTest',
                    args => {
                        got_ref => {
                            '$ref' => 'greeting',
                            '$method' => 'got_args_hash',
                            '$args' => 'hello',
                        },
                    },
                },
                greeting => {
                    class => 'My::ArgsTest',
                    args => {
                        hello => "Hello",
                        default => 'World',
                    },
                },
            },
        );

        subtest 'still works even though deprecated' => sub {
            my $svc;
            lives_ok { $svc = $wire->get( 'foo2' ) };
            isa_ok $svc, 'My::RefTest';
            cmp_deeply $svc->got_ref, [ 'Hello' ] or diag explain $svc->got_ref;
        };

        is scalar @warnings, 1;
        is $warnings[0], qq{warning: (deprecated) Using "\$method" to get a value in a dependency is now "\$call" in service "foo2"\n};

        subtest 'only one warning is emitted per problem' => sub {
            $wire->get( 'foo2' );
            is @warnings, 1;
        };
    };

    subtest 'method with arrayref of arguments (2015-03-29)' => sub {
        # $method is ambiguous with service creation ($class)
        my @warnings;
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
        };

        my $wire = Beam::Wire->new(
            config => {
                foo3 => {
                    class => 'My::RefTest',
                    args => {
                        got_ref => {
                            '$ref' => 'greeting',
                            '$method' => 'got_args_hash',
                            '$args' => [ 'default', 'hello' ],
                        },
                    },
                },
                greeting => {
                    class => 'My::ArgsTest',
                    args => {
                        hello => "Hello",
                        default => 'World',
                    },
                },
            },
        );

        subtest 'still works even though deprecated' => sub {
            my $svc;
            lives_ok { $svc = $wire->get( 'foo3' ) };
            isa_ok $svc, 'My::RefTest';
            cmp_deeply $svc->got_ref, [ 'World', 'Hello' ] or diag explain $svc->got_ref;
        };

        is scalar @warnings, 1;
        is $warnings[0], qq{warning: (deprecated) Using "\$method" to get a value in a dependency is now "\$call" in service "foo3"\n};

        subtest 'only one warning is emitted per problem' => sub {
            $wire->get( 'foo3' );
            is @warnings, 1;
        };
    };

};

done_testing;
