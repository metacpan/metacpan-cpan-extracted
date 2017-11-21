package t::APISchema::Schema;
use lib '.';
use t::test;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema::Schema';
}

sub instantiate : Tests {
    my $schema = APISchema::Schema->new;
    isa_ok $schema, 'APISchema::Schema';
}

sub resource : Tests {
    my $schema = APISchema::Schema->new;

    is $schema->get_resource_by_name('user'), undef;

    cmp_deeply $schema->get_resources, [];

    $schema->register_resource('user' => {
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            age => { type => 'integer' },
        },
        required => ['name', 'age'],
    });

    cmp_deeply $schema->get_resource_by_name('user'), isa('APISchema::Resource') & methods(
        title => 'user',
        definition => {
            type => 'object',
            properties => {
                name  => { type => 'string'  },
                age => { type => 'integer' },
            },
            required => ['name', 'age'],
        },
    );

    is $schema->get_resource_by_name('not_user'), undef;

    cmp_deeply $schema->get_resources, [
        $schema->get_resource_by_name('user'),
    ];
}

sub route : Tests {
    subtest 'Basic' => sub {
        my $schema = APISchema::Schema->new;
        cmp_deeply $schema->get_routes, [];

        $schema->register_route(
            route             => '/bmi/',
            description       => 'This API calculates your BMI.',
            destination       => {
                controller    => 'BMI',
                action        => 'calculate',
            },
            method            => 'POST',
            request_resource  => 'health',
            response_resource => 'bmi',
        );

        cmp_deeply $schema->get_routes, [
            isa('APISchema::Route') & methods(
                route             => '/bmi/',
                description       => 'This API calculates your BMI.',
                destination       => {
                    controller    => 'BMI',
                    action        => 'calculate',
                },
                method            => 'POST',
                request_resource  => 'health',
                response_resource => 'bmi',
            ),
        ];
    };

    subtest 'Naming' => sub {
        my $schema = APISchema::Schema->new;
        cmp_deeply $schema->get_routes, [];

        $schema->register_route(
            title => 'BMI API',
            route => '/bmi/',
        );
        is $schema->get_routes->[0]->title, 'BMI API';

        $schema->register_route(
            route => '/bmi/',
        );
        is $schema->get_routes->[1]->title, '/bmi/';

        $schema->register_route();
        is $schema->get_routes->[2]->title, 'empty_route';

        $schema->register_route(
            title => 'BMI API',
            route => '/bmi/',
        );
        is $schema->get_routes->[3]->title, 'BMI API(1)';

        $schema->register_route(
            title => 'BMI API',
            route => '/bmi/',
        );
        is $schema->get_routes->[4]->title, 'BMI API(2)';

        $schema->register_route(
            route => '/bmi/',
        );
        is $schema->get_routes->[5]->title, '/bmi/(1)';

        $schema->register_route(
            route => '/bmi/',
        );
        is $schema->get_routes->[6]->title, '/bmi/(2)';

        $schema->register_route();
        is $schema->get_routes->[7]->title, 'empty_route(1)';

        $schema->register_route();
        is $schema->get_routes->[8]->title, 'empty_route(2)';
    };
}

sub title_description : Tests {
    my $schema = APISchema::Schema->new;
    is $schema->title, undef;
    is $schema->description, undef;

    $schema->title('BMI');
    is $schema->title, 'BMI';

    $schema->description('The API to calculate BMI');
    is $schema->description, 'The API to calculate BMI';
}
