package Blikistan::MagicEngine::Jemplate;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use JSON;

sub print_blog {
    my $self = shift;
    my $r = $self->{rester};
    
    my $params = $self->load_config($r);
    my $json = objToJson($params);
    $json =~ s/'/\\'/g;
    $json =~ s#<script .+script>##;

    return $self->render_template( { json_data => $json } );
}

1;
