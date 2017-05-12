package # hide from PAUSE
  TestApp::Controller::DBIC;

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

sub users :Path('users') {
    my($self, $ctx) = @_;
    my @users = $self->get_ordered_users($ctx->model('Schema::User'));
    $ctx->res->body(join(',',(map {$_->email} @users)));
}

sub roles :Path('roles') {
    my($self, $ctx) = @_;
    my @roles = $self->get_ordered_roles($ctx->model('Schema::Role'));
    $ctx->res->body(join(',',(map {$_->name} @roles)));
}

sub user_roles :Path('user_roles') :Args(1) {
    my($self, $ctx, $id) = @_;
    my $user = $ctx->model('Schema::User')->find({user_id=>$id});
    $ctx->res->body(join ',', map {$_->name} $user->roles);
    
}

sub get_ordered_users {
    my ($self, $rs) = @_;
    $rs->
        search({}, {order_by => {-asc=>'user_id'}})->
        all;
}

sub get_ordered_roles {
    my ($self, $rs) = @_;
    $rs->
        search({}, {order_by => {-asc=>'role_id'}})->
        all;
}

1;
