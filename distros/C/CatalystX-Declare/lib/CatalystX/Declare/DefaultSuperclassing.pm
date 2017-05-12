use MooseX::Declare;

role CatalystX::Declare::DefaultSuperclassing {

    requires qw(
        default_superclasses
    );

    before add_optional_customizations (Object $ctx, Str $package) {

        unless (@{ $ctx->options->{extends} || [] }) {
            $ctx->options->{extends} = [$self->default_superclasses];
        }
    }
}

