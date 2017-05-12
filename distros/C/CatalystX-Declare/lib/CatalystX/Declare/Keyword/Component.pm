use MooseX::Declare;

class CatalystX::Declare::Keyword::Component
    extends MooseX::Declare::Syntax::Keyword::Class
    with    CatalystX::Declare::DefaultSuperclassing {


    before add_namespace_customizations (Object $ctx, Str $package) {

        $ctx->add_preamble_code_parts(
            'use CLASS',
        );
    }

    method default_superclasses { 'Catalyst::Component' }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::Component - Declare Catalyst Components

=head1 DESCRIPTION

This handler provides common functionality for all component handlers.
Please refer to the respective keyword handler documentation for more
information:

=over

=item L<CatalystX::Declare::Keyword::Model>

=item L<CatalystX::Declare::Keyword::View>

=item L<CatalystX::Declare::Keyword::Controller>

=back

=head1 SUPERCLASSES

=over

=item L<MooseX::Declare::Syntax::Keyword::Class>

=back

=head1 ROLES

=head1 METHODS

These methods are implementation details. Unless you are extending or 
developing L<CatalystX::Declare>, you should not be concerned with them.

=head2 add_namespace_customizations

    Object->add_namespace_customizations (Object $ctx, Str $package)

This will simply add L<CLASS> to the imported modules, to make C<CLASS>
and C<$CLASS> available in the component.

=head2 default_superclasses

    List[Str] Object->default_superclasses ()

Returns L<Catalyst::Component> as default superclass for components. The
subclasses for other component keywords will usually want to override this.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<CatalystX::Declare::Keyword::Model>

=item L<CatalystX::Declare::Keyword::View>

=item L<CatalystX::Declare::Keyword::Controller>

=item L<MooseX::Declare/class>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
