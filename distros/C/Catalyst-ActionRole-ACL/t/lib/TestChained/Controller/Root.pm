package TestChained::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

my $msg = '';

__PACKAGE__->config(
    namespace => q{},
);

sub index :Local Args(0) {
    my ($self, $c) = @_;
    $c->stash->{msg} = 'index';
}

sub stage1
:Chained('/')
:CaptureArgs(0)
:Does('ACL')
:RequiresRole('admin')
:ACLDetachTo('denied')
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-stage1';
}

sub stage2
:Chained('stage1')
:CaptureArgs(0)
:Does('ACL')
:RequiresRole('superuser')
:ACLDetachTo('denied')
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-stage2';
}

sub edit
:Chained('stage2')
:Does('ACL')
:RequiresRole('editor')
:ACLDetachTo('denied')
:Args(0)
{
    my ($self, $c) = @_;
    $c->stash->{msg} .= '-edit';
    $c->res->body($c->stash->{msg});
}

sub denied :Private {
    my ($self, $c) = @_;

    $c->res->status(403);
    $c->res->body('access denied');
}


__PACKAGE__->meta->make_immutable;

