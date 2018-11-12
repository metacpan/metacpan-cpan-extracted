package Catalyst::Model::InjectionHelpers::PerSession;

use Moose;
use Scalar::Util qw/blessed refaddr/;

with 'Catalyst::ComponentRole::InjectionHelpers'; 

sub restore_from_session {
  my ($self, $c, @args) = @_;
  my $key = blessed $self ? refaddr $self : $self;

  $key = "__InstancePerContext_${key}";

  return $c->stash->{$key} if $c->stash->{$key};
    
  if(exists $c->session->{$self->composed_class}) {
    my $info = $c->session->{$self->composed_class};
    my $thawed = $self->composed_class->thaw($info);
    $thawed->__session($c->session);
    $thawed->__stash($c->stash);
    $thawed->__key($key);

    return $thawed;
  } else { 
    my $new = $self->build_new_instance($c, @args, __session=>$c->session, __key=>$key, __stash=>$c->stash);
    $c->stash->{$key} = $new;
    return $new;
  }
}

around 'BUILDARGS', sub {
  my ($orig, $self, @args) = @_;
  my $args = $self->$orig(@args);
  if($args->{roles}) {
    push @{$args->{roles}}, 'Catalyst::ComponentRole::StoreToSession';
  } else {
    $args->{roles} = ['Catalyst::ComponentRole::StoreToSession'];
  }
  return $args;
};

sub ACCEPT_CONTEXT {
  my ($self, $c, @args) = @_;
  return $self->build_new_instance($c, @args) unless blessed $c;

  unless($c->can('session')) {
    die "Can't use a PerSession model adaptor unless you are using the Session Plugin";
  }

  return $self->restore_from_session($c, @args);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Model::InjectionHelpers::PerSession - Adaptor that returns a session scoped model

=head1 SYNOPSIS

    package MyApp::PerSession;

    use Moose;

    sub freeze {
      my ($self) = @_;
      return $self->id;
    }

    sub thaw {
      my ($self, $from_session) = @_;
      return $self->new_from($from_session);
    }

    package MyApp;

    use Catalyst 'InjectionHelper';

    MyApp->inject_components(
    'Model::PerRequest' => {
      from_class=>'MyApp::PerSession', 
      adaptor=>'PerSession', 
    });

    MyApp->setup;
    
=head1 DESCRIPTION

Injection helper adaptor that returns a new model once for session.
See L<Catalyst::Plugin::InjectionHelpers> for details.  The adapted model
MUST provide the following methods:

=head2 freeze

This method should provide a serialized version of the object suitable for
placing in the session.  To be safe you should provide a string.  We recommend that
you provide the smallest possible token useful for restoring a model at a later time,
such the primary key of a database row, rather than all the data since session space
may be limited, depending on the session type you use.

=head2 thaw

This receives the serialized version of the object that you created with 'freeze'
and you shold use it to restore your object.

=head2 cleanup

Optional.  When calling 'discard' on your model to discard the current saved version
you may need to add this method in order to properly cleanup.  For example if you
save some temporary files as part of freeze, you may wish to remove those.

=head1 NOTE

We consider this adaptor to be someone experimental since its new and is not based on
any existing prior art.  Please register issues so we can improve it for the future.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst::Plugin::InjectionHelpers>
L<Catalyst>, L<Catalyst::Model::InjectionHelpers::Application>,
L<Catalyst::Model::InjectionHelpers::Factory>, L<Catalyst::Model::InjectionHelpers::PerRequest>
L<Catalyst::ModelRole::InjectionHelpers>

=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
