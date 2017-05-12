package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' };

__PACKAGE__->config(namespace => q{});

sub index : Path Args(0) {
    my ($self, $c) = @_;
    $c->response->body('action: index');
}

sub browse :
Local
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->response->body("action: browse");
}

sub add :
Local
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->response->body("action: add");
}

sub create :
Local
Does(Tabs) TabAlias(add)
{
    my ($self, $c) = @_;
    $c->response->body("action: create");
}

sub view :
Local
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->response->body("action: view");
}

sub edit :
Local
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->response->body("action: edit");
}

sub update :
Local
Does(Tabs) TabAlias(edit)
{
    my ($self, $c) = @_;
    $c->response->body("action: update");
}

sub remove :
Local
Does(Tabs) Tab
{
    my ($self, $c) = @_;
    $c->response->body("action: remove");
}

sub delete :
Local
Does(Tabs) TabAlias(remove)
{
    my ($self, $c) = @_;
    $c->response->body("action: delete");
}

sub BUILD_TABS {
    my ($self, $c, $tabs) = @_;
    my (@tabs, $tab);
    my $id = $c->request->param('id');
    my @action_names = $id ? qw(view edit remove) : qw(browse add);

    for (@action_names) {
	$tab = $tabs->{$_} or next;
	$tab->{uri}->query("id=$id") if $id;
	push @tabs, $tab;
    }

    $c->stash->{tabs} = \@tabs;
}

__PACKAGE__->meta->make_immutable;

1;
