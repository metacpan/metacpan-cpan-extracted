package Blikistan::MagicEngine::Simple;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;

sub print_blog {
    my $self = shift;
    my $params = $self->load_config;
    return $self->render_template($params);
}

1;

