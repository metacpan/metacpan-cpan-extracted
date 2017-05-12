package Blikistan::MagicEngine::YamlConfig;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use Socialtext::WikiObject::YAML;

sub load_config {
    my $self   = shift;
    my $rester = $self->{rester};

    my $params = {};
    eval {
        $params = Socialtext::WikiObject::YAML->new(
            rester => $rester,
            page => $self->{config_page},
        )->as_hash;
    };
    warn "Cannot parse yaml on page '$self->{config_page}': $@" if $@;
    return $params;
}

1;
