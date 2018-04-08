package App::Env::App2;

# track the number of times this is invoked
our $cnt = 0;

sub envs
{
    my ( $opt ) = @_;

    $cnt++;

    warn( "App2 $cnt\n" ) if $ENV{APP_ENV_DEBUG};
    return { App2 => $cnt };
}

1;
