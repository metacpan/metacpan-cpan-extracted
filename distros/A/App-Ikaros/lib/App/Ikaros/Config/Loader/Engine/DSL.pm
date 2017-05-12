package App::Ikaros::Config::Loader::Engine::DSL;
use strict;
use warnings;
use App::Ikaros::Config qw/CONFIG/;

sub new {
    my ($class, $options) = @_;
    CONFIG->{options} = $options;
    return bless {}, $class;
}

sub load {
    my ($self, $conf) = @_;
    do $conf;
    if ($@) {
        warn $@;
        exit 1;
    }
    if ($!) {
        warn $!;
        exit 1;
    }
    return CONFIG;
}

1;
