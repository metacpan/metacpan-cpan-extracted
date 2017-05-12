package t::APISchema::Route;
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
