
use HTTP::Tiny;

sub server_alive {
    my $port = $ENV{ARANGO_DB_PORT} || 8529;
    return HTTP::Tiny->new->get("http://$ENV{ARANGO_DB_HOST}:$port")->{success};
}

sub clean_test_environment {
    my $arango = shift;

    my @x = grep { $_ eq "tmp_"} @{$arango->list_databases};
    if (scalar @x) {
        $arango->delete_database("tmp_")
    }

    my @y = grep { $_ eq "tmp_user_" } map { $_->{user} } @{$arango->list_users->{result}};
    if (scalar @y) {
        $arango->delete_user("tmp_user_");
    }
}


sub valid_env_vars {      
    return defined $ENV{ARANGO_DB_HOST} && defined $ENV{ARANGO_DB_USERNAME} && defined $ENV{ARANGO_DB_PASSWORD}
}

