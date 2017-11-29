package t::APISchema::Route;
use lib '.';
use t::test;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema::Route';
}

sub instantiate : Tests {
    my $route = APISchema::Route->new(
        route             => '/bmi/',
        title             => 'BMI API',
        description       => 'This API calculates your BMI.',
        destination       => {
            controller    => 'BMI',
            action        => 'calculate',
        },
        method            => 'POST',
        request_resource  => 'health',
        response_resource => 'bmi',
    );
    cmp_deeply $route, isa('APISchema::Route') & methods(
        route             => '/bmi/',
        title             => 'BMI API',
        description       => 'This API calculates your BMI.',
        destination       => {
            controller    => 'BMI',
            action        => 'calculate',
        },
        method            => 'POST',
        request_resource  => 'health',
        response_resource => 'bmi',
    );
}

sub responsible_codes : Tests {
    subtest 'when simple response resource' => sub {
        my $route = APISchema::Route->new(
            route             => '/bmi/',
            title             => 'BMI API',
            description       => 'This API calculates your BMI.',
            destination       => {
                controller    => 'BMI',
                action        => 'calculate',
            },
            method            => 'POST',
            request_resource  => 'health',
            response_resource => 'bmi',
        );
        cmp_deeply $route->responsible_codes, [200];
        is $route->default_responsible_code, 200;
        ok ! $route->responsible_code_is_specified;
    };

    subtest 'when multiple response codes are specified' => sub {
        my $route = APISchema::Route->new(
            route             => '/bmi/',
            title             => 'BMI API',
            description       => 'This API calculates your BMI.',
            destination       => {
                controller    => 'BMI',
                action        => 'calculate',
            },
            method            => 'POST',
            request_resource  => 'health',
            response_resource => {
                201 => 'bmi',
                401 => 'bmi',
                400 => 'bmi',
            },
        );
        is $route->default_responsible_code, 201;
        ok $route->responsible_code_is_specified;
    };

}
