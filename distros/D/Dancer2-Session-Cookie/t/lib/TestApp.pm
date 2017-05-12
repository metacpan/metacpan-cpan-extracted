package TestApp;

use Dancer2;

get '/no_session_data' => sub {
    return "session not modified";
};

get '/set_session/*' => sub {
    my ($name) = splat;
    session name => $name;
};

get '/read_session' => sub {
    my $name = session('name') || '';
    "name='$name'";
};

get '/change_session_id' => sub {
    if ( app->can('change_session_id') ) {
        app->change_session_id;
        return "change_session_id supported by Dancer2";
    }
    else {
        return "change_session_id not supported by Dancer2";
    }
};

get '/destroy_session' => sub {
    my $name = session('name') || '';
    app->destroy_session;
    return "destroyed='$name'";
};

get '/churn_session' => sub {
    app->destroy_session;
    session name => 'damian';
    return "churned";
};

#setting appdir => $tempdir;
#setting( engines => { session => { $engine => $config } } );
#setting( session => $engine );

set(
    show_errors  => 1,
    startup_info => 0,
    environment  => 'production',
);

1;
