use strict;
use warnings;

use Test::More;
use Test::Warnings;
use File::HomeDir;
use Data::Dumper;

use DBIx::Class::DeploymentHandler::CLI::ConfigReader;

my $home_path = File::HomeDir->my_home;

{
    my $conf_paths = test_paths();

    isa_ok($conf_paths, 'ARRAY');
    is_deeply($conf_paths, [ '.dh-cli', "$home_path/.dh-cli", '/etc/dh-cli' ]);
}

{
    my $conf_paths = test_paths(config_name => 'dh_cli');
    isa_ok($conf_paths, 'ARRAY');
    is_deeply($conf_paths, [ '.dh_cli', "$home_path/.dh_cli", '/etc/dh_cli' ]);
}

{
    $ENV{DBIX_CONFIG_DIR} = 't';
    my $conf_paths = test_paths();
    isa_ok($conf_paths, 'ARRAY');
    is_deeply($conf_paths, [ 't/dh-cli', '.dh-cli', "$home_path/.dh-cli", '/etc/dh-cli' ]);
}

{
    my $conf_reader = DBIx::Class::DeploymentHandler::CLI::ConfigReader->new;
    my $config = $conf_reader->config;
    is_deeply( $config, {
        schema_class => 'Interchange6::Schema',
        databases => [ 'MySQL', 'PostgreSQL' ],
    } );
}

{
    # test config_files accessor
    my $conf_reader = DBIx::Class::DeploymentHandler::CLI::ConfigReader->new(
        config_files => [ "t/dh-cli-extra.yaml" ]);
    my $config = $conf_reader->config;
    is_deeply( $config, {
        schema_class => 'Interchange6::Schema',
        databases => 'PostgreSQL',
    } );
}

{
    # use odd config file name
    my $conf_reader = DBIx::Class::DeploymentHandler::CLI::ConfigReader->new(
        config_name => 'nevairbe'
    );
    my $config = $conf_reader->config;
    ok(! defined $config) || diag "Unexpected configuration: ", Dumper($config);
}

sub test_paths {
    my (@args) = @_;
    my $conf_reader = DBIx::Class::DeploymentHandler::CLI::ConfigReader->new( @args );
    return $conf_reader->config_paths;
}

done_testing;
