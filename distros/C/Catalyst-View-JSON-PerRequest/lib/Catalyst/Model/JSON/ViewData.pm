package Catalyst::Model::JSON::ViewData;

use Moo;
 
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';
with 'Data::Perl::Role::Collection::Hash';
 
sub build_per_context_instance {
  my ($self, $c, %args) = @_;
  return $self->new(%args);
}
 
sub TO_JSON { +{shift->elements} }
 
sub AUTOLOAD {
  my ($self, @args) = @_;
  my $key = our $AUTOLOAD;
  $key =~ s/.*:://;
  return scalar(@args) ?
    $self->set($key, @args)
      : $self->get($key);
}
  
1;

=head1 NAME

Catalyst::Model::JSON::ViewData - Default model for Catalyst::View::JSON::PerRequest

=head1 SYNOPSIS

    sub root :Chained(/) CaptureArgs(0) {
      my ($self, $c) = @_;
      $c->view->data->set(z=>1);
    }

=head1 DESCRIPTION

This is the default model used by L<Catalyst::View::JSON::PerRequest> to
collect information that will be presented as JSON data to the client.

Generally you will access this via '$c->view->data'.  However it is setup as a 
per request model in Catalyst so you can access it via '$c->model("JSON::ViewData")'.
which might have some use if you are populating values in other dependent models.

=head1 METHODS

This model consumes the role L<Data::Perl::Role::Collection::Hash> and gets
all its method from it.

=head1 SEE ALSO

L<Catalyst::View::JSON::PerRequest>, L<Catalyst>, L<Data::Perl>, L<Moo>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
