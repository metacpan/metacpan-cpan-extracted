package Amp::Config;
use Moo;
use JSON::Parse ':all';
use Amp::Util::Strings;
use Amp::DbPoolClient;
use Data::Dumper;
use feature 'say';

has file => (is => 'rw');
has dbsvc => (is => 'ro', default => "http://dashboard-m1.shr.oclc.org");
has _config => (is => 'rw', default => sub {{}});

sub BUILD {
    die("Missing AMP_CONFIG environment variable") if !$ENV{AMP_CONFIG};
    die("Missing AMP_API_KEY environment variable") if !$ENV{AMP_API_KEY};
}

sub key {
    return $ENV{AMP_API_KEY};
}

sub environments {
    my $self = shift;
    return $self->_settings->{environments};
}

sub _settings {
    my $self = shift;
    my $config = read_json($ENV{AMP_CONFIG});

    if (!$self->_config->{environments}) {
        $self->_loadEnvConfig($config);
    }

    return $self->_config;
}


sub _loadEnvConfig {
    my $self = shift;
    my $config = shift;
    if (!$config->{environments}) {
        my $client = Amp::DbPoolClient->new(
            host => $self->dbsvc,
            key  => $config->{key}
        );
        my $environments = $client->getEnvConfig;
        $config->{environments} = $environments;
    }
    $self->_config($config);
}

sub getEnvHash {
    my $self = shift;
    my $environments = $self->environments;

    my $hash;
    for my $env (@{$environments}) {
        $hash->{$env->{id}} = $env->{url};
    }

    return $hash;
}

sub getEnv {
    my $self = shift;
    my $instanceName = shift;
    return $self->getEnvHash->{$instanceName}
}

1;