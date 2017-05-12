package TestApp::Controller::Affe;
our $VERSION = '0.06';

use Moose;
use Scalar::Util 'weaken';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub no_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->response->body('no_closure');
}

sub leak_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(leak_closure => sub {
        $ctx->response->body('from leaky closure');
    });
    $ctx->response->body('leak_closure');
}

sub weak_closure : Local {
    my ($self, $ctx) = @_;
    my $weak_ctx = $ctx;
    weaken $weak_ctx;
    $ctx->stash(weak_closure => sub {
        $weak_ctx->response->body('from weak closure');
    });
    $ctx->response->body('weak_closure');
}

sub leak_closure_indirect : Local {
    my ($self, $ctx) = @_;
    my $ctx_ref = \$ctx;
    $ctx->stash(leak_closure_indirect => sub {
        ${ $ctx_ref }->response->body('from indirect leaky closure');
    });
    $ctx->response->body('leak_closure_indirect');
}

sub weak_closure_indirect : Local {
    my ($self, $ctx) = @_;
    my $ctx_ref = \$ctx;
    weaken $ctx_ref;
    $ctx->stash(weak_closure_indirect => sub {
        ${ $ctx_ref }->response->body('from indirect weak closure');
    });
    $ctx->response->body('weak_closure_indirect');
}

sub stashed_ctx : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(ctx => $ctx);
    $ctx->response->body('stashed_ctx');
}

sub stashed_weak_ctx : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(ctx => $ctx);
    weaken $ctx->stash->{ctx};
    $ctx->response->body('stashed_weak_ctx');
}

1;
