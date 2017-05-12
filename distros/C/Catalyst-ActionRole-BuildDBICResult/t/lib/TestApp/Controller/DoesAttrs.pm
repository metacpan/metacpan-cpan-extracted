package # hide from PAUSE
  TestApp::Controller::DoesAttrs;

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller::ActionRole';
}

__PACKAGE__->config();

sub user_default
  :Path('user_default')
  :Args(1)
  :Does('BuildDBICResult')
  :Store(model=>"Schema::User")
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_default';
}

    sub user_default_FOUND :Action {
        my ($self, $ctx, $user, $id) = @_;
        push @{$ctx->stash->{res}}, $user->email;
    }

    sub user_default_NOTFOUND :Action {
        my ($self, $ctx, $user, $id) = @_;
        push @{$ctx->stash->{res}}, 'notfound';
    }

sub end :Private {
    my ($self, $ctx) = @_;
    if(my $role = $ctx->stash->{role}) {
        my $name = $role->name;
        push @{$ctx->stash->{res}}, $name
    }
    if(my $user = $ctx->stash->{user}) {
        my $email = $user->email;
        push @{$ctx->stash->{res}}, $email;
    }
    if(my $res = $ctx->stash->{res}) {
        $ctx->res->body(join(',', @$res));
    }
}

1;
