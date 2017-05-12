package TestCanVisit::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config(namespace => q{});

sub index :Path Args(0) {
    my ($self, $c) = @_;
    $c->res->body('action: index');
}

sub access :Local {
    my ($self, $c) = @_;

    my $action_name = $c->req->params->{action_name};
    my $action = $c->dispatcher->get_action_by_path($action_name);
    my $rc = $action->can_visit($c);

    $c->res->body($rc ? 'yes' : 'no');
}

sub edit
    :Local
    :Does('ACL')
    :AllowedRole(admin)
    :AllowedRole(editor)
    :ACLDetachTo(denied)
    { }
sub read
    :Local
    :Does('ACL')
    :RequiresRole(user)
    :ACLDetachTo(denied)
    { }

sub denied :Private {
    my ($self, $c) = @_;

    $c->res->status(403);
    $c->res->body('access denied');
}


__PACKAGE__->meta->make_immutable;

