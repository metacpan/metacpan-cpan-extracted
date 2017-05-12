package Catalyst::ComponentRole::StoreToSession;

use Moose::Role;

requires 'freeze', 'thaw';

has [qw/__key __stash __session/] => (is=>'rw', weak_ref=>1);

sub discard {
  my $self = shift;
  my $class = ref $self;
  $self->{__donotsavetosession} = 1;
  $self->cleanup if $self->can('cleanup');
  delete $self->__stash->{$self->__key};
  delete $self->__session->{$class};
  $self = undef;
  return undef;
}

sub DESTROY {
  my $self = shift;
  my $class = ref $self;

  return if $self->{__donotsavetosession};

  $self->__session->{$class} = $self->freeze;
}

=head1 NAME

Catalyst::ComponentRole::StoreToSession - components that can store to session

=head1 DESCRIPTION

No user servicable bits for now, you should see
L<Catalyst::Model::InjectionHelpers::PerSession>

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst::Plugin::InjectionHelpers>
L<Catalyst>, L<Catalyst::Model::InjectionHelpers::Application>,
L<Catalyst::Model::InjectionHelpers::Factory>, L<Catalyst::Model::InjectionHelpers::PerRequest>
L<Catalyst::Model::InjectionHelpers::PerSession>, L<Catalyst::ModelRole::InjectionHelpers>

=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

1;
