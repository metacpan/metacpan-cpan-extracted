use CatalystX::Declare;

# almost like a normal Moose role
controller_role MyApp::Web::ControllerRole::RenderView {

    # we can use the whole Moose infrastructure
    use MooseX::Types::Moose qw( Str );

    # a normal attribute that can be passed by config
    has default_content_type => (
        is          => 'ro',
        isa         => Str,
        required    => 1,
        default     => 'text/html; charset=utf-8',
    );

    # this private end action is a cheap ripoff of Catalyst::Action::RenderView
    action end (@) {

        # do nothing if rendering wouldn't make sense
        return
            if $ctx->request->method eq 'HEAD'
            or ( defined( $ctx->response->body ) and length( $ctx->response->body ) )
            or $ctx->response->status =~ /^(?:204|3\d\d)$/;

        # set the content type from our attribute unless it is already set
        $ctx->response->content_type( $self->default_content_type )
            unless $ctx->response->content_type;

        # find a view
        my $view = $ctx->view
            or die "Unable to find a view to forward to";

        # and forward to it
        $ctx->forward( $view );
    }
}
