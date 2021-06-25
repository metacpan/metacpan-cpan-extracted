package TestApp;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
    $ENV{DANCER_ENVDIR}  = 't/environments';
}

use Dancer2;
use Dancer2::Plugin::PrometheusTiny;

any '/' => sub {
    content_type('text/plain');
    return "Hello World!";
};

any '/test-metrics' => sub {
    prometheus->add( 'test_counter', 2 );
    prometheus->add( 'test_counter', 3 );
    prometheus->set( 'test_gauge', 42 );
    prometheus->histogram_observe( 'test_histogram', 2 );
    prometheus->histogram_observe( 'test_histogram', 3 );
};

1;
