package TestApp;

use Cwd;
use Dancer2;
use Dancer2::Plugin::Minion;

set plugins => {
    'Minion' => {
        dsn     => 'sqlite::memory:',
        backend => 'SQLite',
    },
};

get '/' => sub {
    add_task( foo => sub {
        print STDERR join( ', ', @_ ) . "\n";
    });

    return "OK - Task Added";
};

get '/start' => sub { 
    my $id = enqueue( foo => [ qw( Foo Bar Baz ) ] );
    var job_id => $id;
    return "OK - job $id started";
};

get '/state/:id' => sub {
    my $id = route_parameters->get( 'id' );
    my $state = minion->job( $id )->info->{ state };
    return "State for $id is $state";
};
