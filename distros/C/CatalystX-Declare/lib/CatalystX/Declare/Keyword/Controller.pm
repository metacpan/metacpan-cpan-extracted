use MooseX::Declare;
use Catalyst::Controller;

class CatalystX::Declare::Keyword::Controller
    extends CatalystX::Declare::Keyword::Component {

    use MooseX::MethodAttributes ();
    use aliased 'CatalystX::Declare::Keyword::Action', 'ActionKeyword';
    use aliased 'CatalystX::Declare::Controller::DetermineActionClass';
    use aliased 'CatalystX::Declare::Controller::Meta::TypeConstraintMapping';
    use aliased 'CatalystX::Declare::Controller::ActionPreparation';

    use Data::Dump qw( pp );


    before add_namespace_customizations (Object $ctx, Str $package) {

        MooseX::MethodAttributes->init_meta(for_class => $package);

        $ctx->add_preamble_code_parts(
            ['BEGIN',
                sprintf('Class::MOP::load_class(q(%s))', TypeConstraintMapping),
                sprintf('%s->meta->apply(%s->meta->meta)', TypeConstraintMapping, $package),
            ],
        );
    }

    after add_extends_option_customizations (Object $ctx, Str $package, $superclasses, $options) {

        $ctx->add_scope_code_parts(
            sprintf('with qw( %s )', join ' ',
                DetermineActionClass,
                ActionPreparation,
            ),
        );
    }

    method default_superclasses { 'Catalyst::Controller::ActionRole' }

    method auto_make_immutable { 0 }

    around default_inner {

        my @modifiers = qw( ); 

        return [
            ( grep { my $id = $_->identifier; not grep { $id eq $_ } @modifiers } @{ $self->$orig() || [] } ),
            ActionKeyword->new(identifier => 'action'),
            ActionKeyword->new(identifier => 'under'),
            ActionKeyword->new(identifier => 'final'),
        ];
    }

    method add_with_option_customizations (Object $ctx, $package, ArrayRef $roles, HashRef $options) {

        $package = $ctx->qualify_namespace($package);

        $ctx->add_cleanup_code_parts('Moose::Util::apply_all_roles("' . $package . '", qw/'
            . join(' ', map { $ctx->qualify_namespace($_) } @$roles)
            . '/)')
            if scalar @$roles;

        $ctx->add_cleanup_code_parts(
            sprintf '%s->meta->make_immutable', $package
        ) unless $options->{is}{mutable};
    }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::Controller - Declare Catalyst Controllers

=head1 SYNOPSIS

    controller MyApp::Web::Controller::Example
       extends MyApp::Web::ControllerBase::CRUD
       with    MyApp::Web::ControllerRole::Caching {
    

        $CLASS->config(option_name => 'value');


        has attr => (is => 'rw', lazy_build => 1);

        method _build_attr { 'Hello World' }


        action base as '';

        final action site, under base {
            $ctx->response->body( $self->attr );
        }
    }

=head1 DESCRIPTION

This handler module allows the declaration of Catalyst controllers. The
C<controller> keyword is an extension of the 
L<CatalystX::Declare::Keyword::Component>, which in turn is an extension 
of L<MooseX::Declare/class> with all the
bells and whistles, including C<extends>, C<with>, C<method> and modifier
declarations.

In addition to the keywords and features provided by L<MooseX::Declare>, you
can also specify your controller's actions declaratively. For the whole truth
about the syntax refer to L<CatalystX::Declare::Keyword::Action>.

For controller roles, please see L<CatalystX::Declare::Keyword::Role>. You can
extend controllers with the C<extends> keyword and consume roles via C<with> as
usual.

=head1 SUPERCLASSES

=over

=item L<CatalystX::Declare::Keyword::Component>

=back

=head1 METHODS

These methods are implementation details. Unless you are extending or 
developing L<CatalystX::Declare>, you should not be concerned with them.

=head2 add_namespace_customizations

    Object->add_namespace_customizations (Object $ctx, Str $package)

This method modifier will initialise the controller with 
L<MooseX::MethodAttributes> and add the 
L<CatalystX::Declare::Controller::ActionPreparation> and
L<CatalystX::Declare::Controller::DetermineActionClass> controller roles
before calling the original.

=head2 default_superclasses

    Str Object->default_superclasses ()

Returns L<Catalyst::Controller> as the default superclass for all declared
controllers.

=head2 add_with_option_customizations

    Object->add_with_option_customizations (
        Object   $ctx,
        Str      $package,
        ArrayRef $roles,
        HashRef  $options,
    )

This hook method will be called by L<MooseX::Declare> when C<with> options were
encountered. Since 0.011 the roles will be applied all at once.

This method will also add a callback to make the controller immutable to the
cleanup code parts unless C<is mutable> was specified.

=head2 auto_make_immutable

    Bool Object->auto_make_immutable ()

Returns C<0>, indicating that L<MooseX::Declare> should not make this class
immutable by itself. We will do that in the L</add_with_option_customizations>
method ourselves.

=head2 default_inner

    ArrayRef[Object] Object->default_inner ()

A method modifier around the original. The inner syntax handlers inherited by
L<MooseX::Declare::Syntax::Keyword::Class> are extended with instances of the
L<CatalystX::Declare::Keyword::Action> handler class for the C<action>, 
C<under> and C<final> identifiers.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<CatalystX::Declare::Keyword::Action>

=item L<CatalystX::Declare::Keyword::Component>

=item L<MooseX::Declare/class>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
