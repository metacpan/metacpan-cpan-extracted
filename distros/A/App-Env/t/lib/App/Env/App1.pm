package App::Env::App1;

# track the number of times this is invoked
our $cnt = 0;

sub envs
{
    my ( $opt ) = @_;

    $cnt++;

    warn( "App1 $cnt\n" ) if $ENV{APP_ENV_DEBUG};
    return { App1 => $cnt };
}

1;
