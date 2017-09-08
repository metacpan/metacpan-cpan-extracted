package BioX::Workflow::Command::run::Rules::Directives::Interpolate::Mustache;

use Moose::Role;
use namespace::autoclean;

use Template::Mustache;

sub interpol_directive {
    my $self   = shift;
    my $source = shift;
    my $text   = '';

    #The $ is not always at the beginning
    if ( exists $self->interpol_directive_cache->{$source} && $source !~ m/{/ )
    {
        return $self->interpol_directive_cache->{$source};
    }

    if ( $source !~ m/{/ ) {
        $self->interpol_directive_cache->{$source} = $source;
        return $source;
    }

    $text = Template::Mustache->render( $source, $self );
    $self->interpol_directive_cache->{$source} = $text;
    return $text;
    
}

1;
