package App::Env::AppWhich;

# track the number of times this is invoked
sub envs
{
    my ( $opt ) = @_;
    return { PATH => 't/bin' };
}

1;
