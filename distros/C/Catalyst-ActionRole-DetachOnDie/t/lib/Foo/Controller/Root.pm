package Foo::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

__PACKAGE__->config(namespace => '');

sub base : Chained('/') PathPart('') CaptureArgs(0) Does('DetachOnDie') {
     my ( $self, $c ) = @_;

    $c->stash->{body} = ['base'];
}

sub success : Chained('base') PathPart('success') Args(0) Does('DetachOnDie'){
     my ( $self, $c ) = @_;

    push @{$c->stash->{body}}, 'success';
}

sub fail : Chained('base') PathPart('fail') Args(0) Does('DetachOnDie'){
     my ( $self, $c ) = @_;

    die 'failed';
    push @{$c->stash->{body}}, 'fail';
}

sub fail_ctx_error : Chained('base') PathPart('fail_ctx_error') Args(0) Does('DetachOnDie'){
     my ( $self, $c ) = @_;

    die 'failed';
    push @{$c->stash->{body}}, 'fail_ctx_error';
}

sub middle_fail_1 : Chained('base') PathPart('middle_fail') CaptureArgs(0) Does('DetachOnDie'){
     my ( $self, $c ) = @_;

    die 'failed';
    push @{$c->stash->{body}}, 'middle_fail_1';
}

sub middle_fail_2 : Chained('middle_fail_1') PathPart('') Args(0) Does('DetachOnDie'){
     my ( $self, $c ) = @_;

    push @{$c->stash->{body}}, 'middle_fail_2';
}

sub base_base : Chained('/') PathPart('base') CaptureArgs(0) ActionClass('DetachOnDie') {
     my ( $self, $c ) = @_;

    $c->stash->{body} = ['base_base'];
}

sub base_success : Chained('base_base') PathPart('success') Args(0) ActionClass('DetachOnDie'){
     my ( $self, $c ) = @_;

    push @{$c->stash->{body}}, 'success';
}

sub base_fail : Chained('base_base') PathPart('fail') Args(0) ActionClass('DetachOnDie'){
     my ( $self, $c ) = @_;

    die 'failed';
    push @{$c->stash->{body}}, 'fail';
}

sub base_middle_fail_1 : Chained('base_base') PathPart('middle_fail') CaptureArgs(0) ActionClass('DetachOnDie'){
     my ( $self, $c ) = @_;

    die 'failed';
    push @{$c->stash->{body}}, 'middle_fail_1';
}

sub base_middle_fail_2 : Chained('base_middle_fail_1') PathPart('') Args(0) ActionClass('DetachOnDie'){
     my ( $self, $c ) = @_;

    push @{$c->stash->{body}}, 'middle_fail_2';
}

sub explicit_detach : Chained('base_base') PathPart('explicit_detach') CaptureArgs(0) ActionClass('DetachOnDie') {
  my($self, $c) = @_;
  push @{$c->stash->{body}}, 'explicit_detach';
  $c->res->redirect('/success');
  $c->detach;
}

sub explicit_detach_endpoint : Chained('explicit_detach') PathPart('endpoint') Args(0) {
  my($self, $c) = @_;
  push @{$c->stash->{body}}, 'endpoint';
  return;
}

sub pitch_go : Chained('base') Args(0) ActionClass('DetachOnDie') {
    my ( $self, $c ) = @_;
    push @{$c->stash->{body}}, 'pitched';
    $c->go('/catch_go');
}

sub catch_go : Action {
    my ( $self, $c ) = @_;
    push @{$c->stash->{body}}, 'caught';
}


sub end : ActionClass('RenderView') {
   my ($self, $c) = @_;

   if ($c->action->name eq 'fail_ctx_error') {
       my $error_count = @{$c->error};
       unshift @{$c->stash->{body}}, $error_count;
   }
   $c->res->header('X-DetachOnDie-Caught', scalar(@{ $c->error }));
   $c->clear_errors;
   $c->response->body(join ', ', @{$c->stash->{body}});
}

__PACKAGE__->meta->make_immutable;

1;
