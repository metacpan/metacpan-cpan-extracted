use Test2::V0;

BEGIN {
    require Config::App;

    local $@;
    eval {
        Config::App->import('config/broken.yaml');
    };

    ok( $@ =~ m|Failed to parse "config/broken.yaml"; YAML::XS::Load Error|, 'Throw error on bad YAML' );
}

done_testing;
