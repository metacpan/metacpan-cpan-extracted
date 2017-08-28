package BioX::Workflow::Command::run::Rules::Directives::Types::Glob;

use Moose::Role;
use File::Glob;

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_types(
        'glob',
        {
            builder => 'create_reg_attr',
            lookup  => ['.*glob$']
        }
    );

    $self->set_register_process_directives( 'glob',
        { builder => 'process_directive_glob', lookup => ['.*_glob$'] } );
};

sub process_directive_glob {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    my $data = glob($v);
    $self->$k($data);
}

1;
