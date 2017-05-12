use MooseX::Declare;

class CatalystX::Declare::Keyword::Role
    extends MooseX::Declare::Syntax::Keyword::Role {


    use aliased 'MooseX::MethodAttributes::Role::Meta::Role';
    use aliased 'MooseX::Role::Parameterized::Meta::Role::Parameterizable';
    use aliased 'CatalystX::Declare::Keyword::Action',  'ActionKeyword';


    around import_symbols_from (Object $ctx) {

        $ctx->has_parameter_signature
        ? $self->$orig($ctx)
        : sprintf('Moose::Role -traits => q(MethodAttributes),')
    }

    before add_namespace_customizations (Object $ctx, Str $package) {

        my $source  = $self->import_symbols_from($ctx);
        my @symbols = $self->imported_moose_symbols;

        $ctx->add_preamble_code_parts(
            'use CLASS',
        );
    }

    after add_namespace_customizations (Object $ctx, Str $package) {

        $ctx->add_preamble_code_parts(
            sprintf(
                'use %s -traits => q(%s), qw( has )',
                'MooseX::Role::Parameterized',
                'MooseX::MethodAttributes::Role::Meta::Role',
            ),
        ) if $ctx->has_parameter_signature;
    }

    around default_inner (@args) {

        return [ 
            @{ $self->$orig(@args) },
            ActionKeyword->new(identifier => 'action'),
            ActionKeyword->new(identifier => 'under'),
            ActionKeyword->new(identifier => 'final'),
        ];
    }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::Role - Declare Catalyst Controller Roles

=head1 SYNOPSIS

    use CatalystX::Declare;

    controller_role MyApp::Web::ControllerRole::Foo {

        method provided_method { ... }

        action foo, under base, is final { ... }

        around bar_action (Object $ctx) { ... }
    }

    controller_role MyApp::Web::ControllerRole::WithParam (Str :$msg!) {

        final action message under base {
            $ctx->stash(message => $msg);
        }
    }

=head1 DESCRIPTION

This handler provides the C<controller_role> keyword. It is an extension of the
L<MooseX::Declare::Syntax::Keyword::Role> handler. Like with declared 
controllers, the C<method> keyword and the modifiers are provided. For details
on the syntax for action declarations have a look at
L<CatalystX::Declare::Keyword::Action>, which also documents the effects of
method modifiers on actions.

=head2 Parameters

You can use a parameter signature containing named parameters for a role. To
apply the controller role in the L</SYNOPSIS>, you'd use code like this:

    controller MyApp::Web::Controller::Hello {
        with 'MyApp::Web::ControllerRole::WithParam' => { msg => 'Hello!' };

        action base under '/' as '';
    }

You can currently only use the parameters in action declarations in the body,
te name, the C<as> path part and the C<under> base action specification:

    controller_role Foo (Str :$base, Str :$part) {

        action foo under $base as $part { ... }
    }

You can specify the parameters either as plain scalar variables or as quoted
strings. The latter is especially useful for more complex path parts:

    action foo under $base as "$pathpart/fnord" { ... }

To use it in the action name is rather simple:

    final action $foo { ... }

You might want to use the C<as $foo> option to specify a path part instead, 
though. Use the dynamic action name possibility only if you are really 
concerned with the name of the generated method, not only the path the 
action is reachable under.

=head1 SUPERCLASSES

=over

=item L<MooseX::Declare::Syntax::Keyword::Role>

=back

=head1 METHODS

=head2 add_namespace_customizations

    Object->add_namespace_customizations (Object $ctx, Str $package)

This hook is called by L<MooseX::Declare> and will set the package up as a role
and apply L<MooseX::MethodAttributes>.

=head2 default_inner

    ArrayRef[Object] Object->default_inner ()

Same as L<CatalystX::Declare::Keyword::Class/default_inner>.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<MooseX::Declare/role>

=item L<CatalystX::Declare::Keyword::Action>

=item L<CatalystX::Declare::Keyword::Controller>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
