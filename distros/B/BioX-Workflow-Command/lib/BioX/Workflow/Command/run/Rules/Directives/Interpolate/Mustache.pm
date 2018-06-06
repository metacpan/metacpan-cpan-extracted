package BioX::Workflow::Command::run::Rules::Directives::Interpolate::Mustache;

use Moose::Role;
use namespace::autoclean;

use Template::Mustache;

has 'delimiter' => (
    is      => 'rw',
    isa     => 'Str',
    default => '{',
);

has 'sample_var' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '{{{sample}}}',
);

sub interpol_directive {
    my $self   = shift;
    my $k = shift;
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

    ##If its the same and it has a $sign, its probably a perl expression
    if ($text eq $source && $text =~ m/\$/){
        return $self->interpol_text_template($source);
    }
    return $text;

}

1;
