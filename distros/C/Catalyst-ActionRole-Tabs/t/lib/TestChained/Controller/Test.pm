package TestChained::Controller::Test;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' };

sub root :
Chained(/) PathPart(test) CaptureArgs(0)
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= 'root';
}

sub id :
Chained(root) PathPart CaptureArgs(1)
{
    my ($self, $c, $id) = @_;
    $c->stash->{id} = $id;
    $c->stash->{msg} .= '-id';
}

sub browse :
PathPart('') Chained(root) Args(0)
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-browse';
}

sub add :
PathPart Chained(root) Args(0)
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-add';
}

sub create :
PathPart Chained(root) Args(0)
Does(Tabs) TabAlias(add)
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-create';
}

sub view :
PathPart('') Chained(id) Args(0)
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-view';
}

sub edit :
PathPart Chained(id) Args(0)
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-edit';
}

sub update :
PathPart Chained(id) Args(0)
Does(Tabs) TabAlias(edit)
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-update';
}

sub remove :
PathPart Chained(id) Args(0)
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-remove';
}

sub delete :
PathPart Chained(id) Args(0)
Does(Tabs) TabAlias(remove)
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-delete';
}

sub end : Private {
    my ($self, $c) = @_;
    $c->response->body($c->stash->{msg});
}

sub BUILD_TABS {
    my ($self, $c, $tabs) = @_;
    my (@tabs, $tab);

    for (qw(browse add view edit remove)) {
      $tab = $tabs->{$_}
        and push @tabs, $tab;
    }

    $c->stash->{tabs} = \@tabs;
}

__PACKAGE__->meta->make_immutable;

1;
