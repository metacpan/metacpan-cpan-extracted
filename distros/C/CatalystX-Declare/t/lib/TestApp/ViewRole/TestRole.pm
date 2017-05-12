use MooseX::Declare;

role TestApp::ViewRole::TestRole {

    around render (Object $ctx) {

        if (my $tag = $ctx->stash->{role_tag}) {
            return join ' ' => $self->$orig($ctx), $tag;
        }

        return $self->$orig($ctx);
    }
}
