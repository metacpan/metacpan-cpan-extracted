package BioX::Workflow::Command::run::Rules::Directives::Types::Mustache;

use Moose::Role;
use namespace::autoclean;

use Template::Mustache;
use Template::Mustache::Trait;
use File::Glob;
use File::Basename;

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_types(
        'mustache',
        {
            builder => 'create_reg_attr',
            lookup  => ['.*_mustache$']
        }
    );

    $self->set_register_process_directives( 'mustache',
        { builder => 'process_directive_mustache', lookup => ['.*_mustache$'] }
    );
};

sub process_directive_mustache {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    return $v;
}

sub create_mustache_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
        $k => (
            is      => 'rw',
            traits  => ['Mustache'],
            handles => {
                'render_' . $k => 'render',
            },
            lazy_build => 1,
        )
    );
}

sub render_mustache {
    my $self     = shift;
    my $template = shift;
    my $print    = shift;

    my $text = Template::Mustache->render( $template, $self );
    print $text if $print;
    return $text;
}

1;
