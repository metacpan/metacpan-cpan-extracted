use CatalystX::Declare;

model TestApp::Model::TestModel {

    use MooseX::Types::Moose qw( Int );

    has counter => (
        is          => 'rw',
        isa         => Int,
        required    => 1,
        default     => 0,
    );

    method next {
        $self->counter( $self->counter + 1 );
        return $self->counter;
    }

    method reset {
        $self->counter(0);
        return 'reset';
    }
}
