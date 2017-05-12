package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config(namespace => q{});

sub index :Path Args(0) {
    my ($self, $c) = @_;
    $c->res->body('action: index');
}

sub edit
:Local
:Does('ACL')
:RequiresRole(editor)
:ACLDetachTo(denied)
{
    my ($self, $c) = @_;
    $c->res->body("action: edit");
}

sub killit
:Local
:Does('ACL')
:RequiresRole(killer)
:ACLDetachTo(denied)
{
    my ($self, $c) = @_;
    $c->res->body("action: killit");
}

sub crews
:Local
:Does('ACL')
:RequiresRole(editor)
:RequiresRole(banana)
:ACLDetachTo(denied)
{
    my ($self, $c) = @_;
    $c->res->body("action: crews");
}

sub reese
:Local
:Does('ACL')
:AllowedRole(sarah)
:AllowedRole(shahi)
:ACLDetachTo(denied)
{
    my ($self, $c) = @_;
    $c->res->body("action: reese");
}

sub wolverines
:Local
:Does('ACL')
:RequiresRole('swayze')
:AllowedRole('actor')
:AllowedRole('guerilla')
:ACLDetachTo(denied)
{
    my ($self, $c) = @_;
    $c->res->body("action: wolverines");
}

sub denied :Private {
    my ($self, $c) = @_;

    $c->res->status(403);
    $c->res->body('access denied');
}


__PACKAGE__->meta->make_immutable;

