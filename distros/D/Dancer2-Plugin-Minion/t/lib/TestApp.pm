package TestApp;

use Cwd;
use Dancer2;
use Dancer2::Plugin::Minion;

add_task( foo => sub {
    my $job = shift;
    return join( ', ', @_ ) . "\n";
});

get '/' => sub {
    my $id = enqueue( foo => [ qw( Foo Bar Baz ) ] );
    var job_id => $id;
    return "OK - job $id started";
};

get '/run' => sub { 
    minion->perform_jobs;
    return "OK - Task Running";
};

get '/state/:id' => sub {
    my $id = route_parameters->get( 'id' );
    my $state = minion->job( $id )->info->{ state };
    return "State for $id is $state";
};
