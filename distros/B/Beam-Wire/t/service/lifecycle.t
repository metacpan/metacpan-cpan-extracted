
use Test::More;
use Test::Lib;
use Scalar::Util qw( refaddr );
use Beam::Wire;

subtest 'singleton lifecycle (the default)' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                lifecycle => 'singleton',
            },
            bar => {
                class => 'My::RefTest',
                args => {
                    got_ref => { '$ref' => 'foo' },
                },
            },
        },
    );

    my $foo = $wire->get('foo');
    isa_ok $foo, 'My::ArgsTest';
    my $oof = $wire->get('foo');
    is refaddr $oof, refaddr $foo, 'same foo object is returned';
    my $bar = $wire->get('bar');
    is refaddr $bar->got_ref, refaddr $foo, 'same foo object is given to bar';
};

subtest 'factory lifecycle' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                lifecycle => 'factory',
            },
            bar => {
                class => 'My::RefTest',
                args => {
                    got_ref => { '$ref' => 'foo' },
                },
            },
        },
    );

    my $foo = $wire->get('foo');
    isa_ok $foo, 'My::ArgsTest';
    my $oof = $wire->get('foo');
    isnt refaddr $oof, refaddr $foo, 'different foo object is returned';
    my $bar = $wire->get('bar');
    isnt refaddr $bar->got_ref, refaddr $foo, 'different foo object is given to bar';
    isnt refaddr $bar->got_ref, refaddr $oof, 'different foo object is given to bar';
};

subtest 'eager lifecycle' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
            },
            bar => {
                class => 'My::RefTest',
                lifecycle => 'eager',
                args => {
                    got_ref => { '$ref' => 'foo' },
                },
            },
        },
    );

    # Reach inside the services to avoid get() creating the service
    my $bar = $wire->services->{bar};
    isa_ok $bar, 'My::RefTest', 'bar exists without calling get()';
    is refaddr $bar->got_ref, refaddr $wire->get('foo'),
        'foo is also created, because bar depends on foo';
};

subtest 'default lifecycle is singleton' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
            },
            bar => {
                class => 'My::RefTest',
                args => {
                    got_ref => { '$ref' => 'foo' },
                },
            },
        },
    );

    my $foo = $wire->get('foo');
    isa_ok $foo, 'My::ArgsTest';
    my $oof = $wire->get('foo');
    is refaddr $oof, refaddr $foo, 'same foo object is returned';
    my $bar = $wire->get('bar');
    is refaddr $bar->got_ref, refaddr $foo, 'same foo object is given to bar';
};

done_testing;
