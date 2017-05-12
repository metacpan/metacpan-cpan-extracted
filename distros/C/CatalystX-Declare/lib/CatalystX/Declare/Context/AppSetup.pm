use MooseX::Declare;

role CatalystX::Declare::Context::AppSetup {

    use MooseX::Types::Moose qw( Bool );
    use Carp                 qw( croak );


    has setup_was_called => (
        is          => 'rw',
        isa         => Bool,
    );

    method add_setup_code_parts (Str $package, ArrayRef $plugins = []) {

        if ($self->setup_was_called) {
            croak 'call to setup already pushed to cleanup code parts';
        }

        $self->add_cleanup_code_parts(
            sprintf(
                '%s->setup(qw( %s ))',
                $package,
                join(' ', @$plugins),
            ),
            '1;',
        );
        $self->setup_was_called(1);
    }
}

