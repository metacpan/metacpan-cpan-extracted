package App::Ikaros::Config::Loader::Engine::YAML;
use strict;
use warnings;
use YAML::XS qw/LoadFile/;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub load {
    my ($self, $conf) = @_;
    return LoadFile $conf;
}

1;
