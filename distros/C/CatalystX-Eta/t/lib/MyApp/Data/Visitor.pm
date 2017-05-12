package MyApp::Data::Visitor;

use namespace::autoclean;
use Moose;

extends 'Data::Visitor';

has current_path => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        add_path_part => 'push',
        path_size     => 'count',
        _back         => 'pop',
        full_path     => [ join => '.' ],
        _clear_path   => 'clear',
    }
);

has final_value => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    clearer => '_clear_final_value'
);

sub visit_hash {
    my ( $self, $href ) = @_;
    for my $key ( keys %$href ) {
        $self->add_path_part($key);
        if ( ref $href->{$key} eq 'HASH' ) {
            $self->visit( $href->{$key} );
            $self->_back;
        }
        else {
            $self->final_value->{ $self->full_path } = $href->{$key};
        }
    }
}

1;
