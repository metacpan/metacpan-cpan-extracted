package Catalyst::ActionRole::CurrentModel;

use Moose::Role;

requires 'attributes';

has current_model => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_build_current_model' );

  sub _build_current_model {
    my $self = shift;
    my ($current_model) = @{$self->attributes->{Model} || []};
    return $current_model;
  }

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  $ctx->stash(current_model=>$self->current_model) if $self->current_model;
  return $self->$orig($controller, $ctx, @args);
};


1;

=head1 NAME

Catalyst::ActionRole::CurrentModel - Set the current model via an action attribute

=head1 SYNOPSIS

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    # Same as $c->stash(current_model => 'Schema::Person');
    sub root :Chained(/) Does(CurrentModel) Model(Schema::Person) {
      my ($self, $c) = @_;
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Just an actionrole to let you set the current model via an attribute

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2021 the above named AUTHOR and CONTRIBUTORS
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
