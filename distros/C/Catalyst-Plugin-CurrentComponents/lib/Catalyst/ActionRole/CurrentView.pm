package Catalyst::ActionRole::CurrentView;

use Moose::Role;

requires 'attributes';

has current_view => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_build_current_view' );

  sub _build_current_view {
    my $self = shift;
    my ($current_view) = @{$self->attributes->{View} || []};
    return $current_view;
  }

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  $ctx->stash(current_view=>$self->current_view) if $self->current_view;
  return $self->$orig($controller, $ctx, @args);
};


1;

=head1 NAME

Catalyst::ActionRole::CurrentView - Set the current view via an action attribute

=head1 SYNOPSIS

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    # Same as $c->stash(current_view => 'HTML');
    sub root :Chained(/) Does(CurrentView) View(HTML) {
      my ($self, $c) = @_;
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Just an actionrole to let you set the current view via an attribute

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2021 the above named AUTHOR and CONTRIBUTORS
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
