use MooseX::Declare;

role CatalystX::Declare::Dispatching::ChainTypeSensitivity {

    use constant CatchValidationError => 'CatalystX::Declare::Action::CatchValidationError';

    our @LastPathParts;


    around recurse_match ($ctx, Str $parent, ArrayRef $path_parts) {

        my @last_path_parts  = @LastPathParts;
        local @LastPathParts = @$path_parts;

        my $action = $ctx->dispatcher->get_action_by_path($parent);

        if ($action and $action->DOES(CatchValidationError)) {

            my @action_parts   = @last_path_parts[0 .. ( $#last_path_parts - @$path_parts )];
            my $path_part_spec = ( @{ $action->attributes->{PathPart} || [] } )[0];
            $path_part_spec    = $action->name
                unless defined $path_part_spec;
            my @name_parts     = grep { $_ ne '' } split qr{/}, $path_part_spec;

            shift @action_parts
                for 0 .. $#name_parts;

            my $tc   = $action->method_type_constraint;
            my $ctrl = $action->controller_instance;
            my $np   = $action->extract_named_params($ctx);

            return ()
                unless $tc->_type_constraint->check([[$ctrl, $ctx, @action_parts], $np]);
        }

        $self->$orig($ctx, $parent, $path_parts);
    }
}
