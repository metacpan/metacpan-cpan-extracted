package t::APISchema::Generator::Router::Simple;
use lib '.';
use t::test;
use t::test::fixtures;
use APISchema::Schema;
use Router::Simple;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema::Generator::Router::Simple';
}

sub instantiate : Tests {
    my $generator = APISchema::Generator::Router::Simple->new;
    isa_ok $generator, 'APISchema::Generator::Router::Simple';
}

sub generate : Tests {
    my $schema = t::test::fixtures::prepare_bmi;

    my $generator = APISchema::Generator::Router::Simple->new;
    my $router = $generator->generate_router($schema);

    isa_ok $router, 'Router::Simple';

    cmp_deeply $router->match({ PATH_INFO => '/bmi', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ), {
        controller      => 'BMI',
        action          => 'calculate',
    };

    note $router->as_string;
}

sub inject_routes : Tests {
    my $schema = t::test::fixtures::prepare_bmi;

    my $router = Router::Simple->new;
    $router->connect('/', {controller => 'Root', action => 'show'});

    my $generator = APISchema::Generator::Router::Simple->new;
    my $returned_router = $generator->inject_routes($schema => $router);

    is $returned_router, $router;

    isa_ok $router, 'Router::Simple';

    cmp_deeply $router->match({ PATH_INFO => '/bmi', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ), {
        controller      => 'BMI',
        action          => 'calculate',
    };

    cmp_deeply $router->match({ PATH_INFO => '/', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GETPOST' } ), {
        controller      => 'Root',
        action          => 'show',
    };
}

sub generate_custom_router : Tests {
    my $generator = APISchema::Generator::Router::Simple->new(
        router_class => 'Test::Router::Simple',
    );
    my $schema = APISchema::Schema->new;
    my $router = $generator->generate_router($schema);
    isa_ok $router, 'Test::Router::Simple';
}

package Test::Router::Simple;
use parent qw(Router::Simple);

package t::APISchema::Generator::Router::Simple;
