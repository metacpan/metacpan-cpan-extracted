use MooseX::Declare;

role CatalystX::Declare::Controller::Meta::TypeConstraintMapping {

    use MooseX::Types::Moose qw( HashRef Object ArrayRef Str CodeRef );

    use aliased 'Moose::Meta::TypeConstraint';
    use aliased 'MooseX::Method::Signatures::Meta::Method', 'MethodWithSignature';

    has method_type_constraint_map => (
        traits    => [ 'Hash' ],
        is          => 'ro',
        isa         => HashRef[Object],
        required    => 1,
        lazy_build  => 1,
        handles    => {
            'get_method_type_constraint' => 'get',
            'set_method_type_constraint' => 'set',
        },
    );

    has method_named_param_map => (
        traits    => [ 'Hash' ],
        is          => 'ro',
        isa         => HashRef[ArrayRef[Str]],
        required    => 1,
        lazy_build  => 1,
        handles    => {
            'get_method_named_params' => 'get',
            'set_method_named_params' => 'set',
        },
    );

    has method_named_type_constraint_map => (
        traits    => [ 'Hash' ],
        is          => 'ro',
        isa         => HashRef[HashRef[Object]],
        required    => 1,
        lazy_build  => 1,
        handles    => {
            'get_method_named_type_constraint' => 'get',
            'set_method_named_type_constraint' => 'set',
        },
    );

    method _build_method_type_constraint_map {
        return +{};
    }

    method _build_method_named_type_constraint_map {
        return +{};
    }

    method _build_method_named_param_map {
        return +{};
    }

    around add_method ($method_name, $method) {

        if (is_Object $method and $method->isa(MethodWithSignature)) {

            my $tc = $method->type_constraint;

            $self->set_method_type_constraint(
                $method_name,
                $tc,
            );

            if ($method->parsed_signature->has_named_params) {
                my $named = $method->parsed_signature->named_params;

                $self->set_method_named_params(
                    $method_name,
                    [ map $_->label, @$named ],
                );
                $self->set_method_named_type_constraint(
                    $method_name,
                    { map +($_->label, $_->meta_type_constraint), @$named },
                );
            }
        }

        return $self->$orig($method_name, $method);
    }

    method _find_capable_classes (CodeRef $test) {

        return
            grep { local $_ = $_; $_->$test }
            $self,
            map  { $_->meta }
            grep { $_->can('meta') }
                 $self->linearized_isa;
    }

    method find_method_named_params (Str $name) {

        my @parents = $self->_find_capable_classes(sub { $_->can('get_method_named_params') });

        for my $isa (@parents) {

            if (my $named = $isa->get_method_named_params($name)) {
                return [@$named];
            }
        }

        return undef;
    }

    method find_method_named_type_constraint (Str $method, Str $param) {

        my @parents = $self->_find_capable_classes(sub { $_->can('get_method_named_type_constraint') });

        for my $isa (@parents) {

            if (my $named = $isa->get_method_named_type_constraint($method)) {
                return $named->{ $param };
            }
        }

        return undef;
    }

    method find_method_type_constraint (Str $name) {

        my @parents = $self->_find_capable_classes(sub { $_->can('get_method_type_constraint') });

        for my $isa (@parents) {
            
            if (my $tc = $isa->get_method_type_constraint($name)) {
                return $tc;
            }
        }

        return undef;
    }
}

