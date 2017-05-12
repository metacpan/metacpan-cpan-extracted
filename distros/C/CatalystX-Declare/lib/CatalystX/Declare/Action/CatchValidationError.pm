use MooseX::Declare;

role CatalystX::Declare::Action::CatchValidationError {

    use MooseX::Types::Moose qw( ArrayRef Str HashRef );
    use aliased 'Moose::Meta::TypeConstraint';

    has method_type_constraint => (
        is          => 'rw',
        isa         => TypeConstraint,
        handles     => {
            _check_action_arguments => 'check',
        },
    );

    has method_named_params => (
        is          => 'rw',
        isa         => ArrayRef[Str],
    );

    has method_named_type_constraint => (
        is          => 'rw',
        isa         => HashRef[TypeConstraint],
    );

    has controller_instance => (
        is          => 'rw',
        isa         => 'Catalyst::Controller',
        weak_ref    => 1,
    );

    method extract_named_params (Object $ctx) {

        my %extracted;
        my $tcs = $self->method_named_type_constraint;
        
        if (my $named = $self->method_named_params) {

            for my $key (@$named) {

                my $value = $ctx->request->params->{ $key };
                my $tc    = $tcs->{ $key };
                
                if ($tc and $tc->is_subtype_of(ArrayRef)) {

                    $value = []
                        unless exists $ctx->request->params->{ $key };

                    $value = [$value]
                        unless is_ArrayRef $value;
                }
                else {
                    
                    next unless exists $ctx->request->params->{ $key };
                }

                $extracted{ $key } = $value;
            }
        }

        return \%extracted;
    }

    around execute (Object $ctrl, Object $ctx, @rest) {

        return $self->$orig($ctrl, $ctx, @rest, %{ $self->extract_named_params($ctx) });
    }

    around match (Object $ctx) {

        return 
            unless $self->$orig($ctx);
        return 1 
            unless $self->method_type_constraint;

        my @args    = ($self->controller_instance, $ctx, @{ $ctx->req->args });
        my $tc      = $self->method_type_constraint;
        my $np      = $self->extract_named_params($ctx);
        my $ret     = $tc->_type_constraint->check([\@args, $np]);

        return $ret;
    }
}
