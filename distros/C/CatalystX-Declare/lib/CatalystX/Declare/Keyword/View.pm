use MooseX::Declare;

class CatalystX::Declare::Keyword::View
    extends CatalystX::Declare::Keyword::Component {

    method default_superclasses { 'Catalyst::View' }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::View - Declare Catalyst Views

=head1 SYNOPSIS

    use CatalystX::Declare;

    view MyApp::Web::View::Example
        extends Catalyst::View::TT 
        with    MyApp::Web::ViewRole::Caching {

        after process (Object $ctx) {
            $ctx->log->debug('done processing at ' . time)
                if $ctx->debug;
        }
    }

=head1 DESCRIPTION

This handler is a direct extension of L<CatalystX::Declare::Keyword::Component>
and provides a C<view> keyword to declare a catalyst view. Currently, the only
things this declaration does is setting up a L<Moose> class like 
L<MooseX::Declare> does, provide L<CLASS> to its scope and default the 
superclass to L<Catalyst::View>.

See L<MooseX::Declare/class> for more information on this kind of keyword. 
Since views do not take actions, no special handling of roles is required, 
other than with controller roles. So if you want to write roles for views, 
simply use the L<MooseX::Declare/role> syntax.

=head1 SUPERCLASSES

=over

=item L<CatalystX::Declare::Keyword::Component>

=back

=head1 METHODS

These methods are implementation details. Unless you are extending or 
developing L<CatalystX::Declare>, you should not be concerned with them.

=head2 default_superclasses

    List[Str] Object->default_superclasses ()

Defaults to L<Catalyst::View>.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<CatalystX::Declare::Keyword::Component>

=item L<MooseX::Declare/class>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
