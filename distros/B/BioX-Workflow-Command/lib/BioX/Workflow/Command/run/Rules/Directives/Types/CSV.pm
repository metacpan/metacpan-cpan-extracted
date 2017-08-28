package BioX::Workflow::Command::run::Rules::Directives::Types::CSV;

use Moose::Role;
use Text::CSV::Slurp;

with 'BioX::Workflow::Command::run::Rules::Directives::Types::Roles::File';

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_types(
        'csv',
        {
            builder => 'create_reg_attr',
            lookup  => ['.*csv$']
        }
    );

    $self->set_register_process_directives( 'csv',
        { builder => 'process_directive_csv', lookup => ['.*_csv$'] } );
};

sub process_directive_csv {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    my $file = $self->check_file_exists( $k, $v );
    return unless $file;

    my $data = Text::CSV::Slurp->load( file => $file );

    if ( exists $v->{key} ) {
        my $key = $v->{key};
        my %hoh = map { $_->{$key} => $_ } @{$data};
        $self->$k( \%hoh );
        return;
    }

    $self->$k($data);
}

1;
