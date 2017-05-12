package Bot::Cobalt::Core::Role::IRC;
$Bot::Cobalt::Core::Role::IRC::VERSION = '0.021003';
use 5.10.1;
use strictures 2;
no warnings 'once';

use Bot::Cobalt::Common ':types';

use Scalar::Util 'blessed';


use Moo::Role;
requires qw/ log debug /;


has 'Servers' => (
  is      => 'rw', 
  isa     => HashRef,
  default => sub { +{} },
);


sub is_connected {
  my ($self, $context) = @_;
  return unless $context and exists $self->Servers->{$context};
  $self->Servers->{$context}->connected
}

*get_irc_server = *get_irc_context;
sub get_irc_context {
  my ($self, $context) = @_;
  return unless defined $context and exists $self->Servers->{$context};
  $self->Servers->{$context}
}

*get_irc_object = *get_irc_obj;
sub get_irc_obj {
  my ($self, $context) = @_;
  if (! $context) {
    $self->log->warn(
      "get_irc_obj called with no context at "
        .join ' ', (caller)[0,2]
    );
    return
  }

  my $c_obj = $self->get_irc_context($context);
  unless ($c_obj && blessed $c_obj) {
    $self->log->warn(
      "get_irc_obj called but context $context not found at "
        .join ' ', (caller)[0,2]
    );
    return
  }
  
  blessed $c_obj->irc ? $c_obj->irc : ()
}

sub get_irc_casemap {
  my ($self, $context) = @_;
  if (! $context) {
    $self->log->warn(
      "get_irc_casemap called with no context at "
        .join ' ', (caller)[0,2]
    );
    return
  }

  my $c_obj = $self->get_irc_context($context);
  unless ($c_obj && blessed $c_obj) {
    $self->log->warn(
      "get_irc_casemap called but context $context not found at "
        .join ' ', (caller)[0,2]      
    );
    return
  }

  $c_obj->casemap
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::Role::IRC

=head1 SYNOPSIS

  ## From a Cobalt plugin
  ## Get this context's Bot::Cobalt::IRC::Server object:
  my $context_obj = $core->get_irc_context( $context );
  
=head1 DESCRIPTION

L<Bot::Cobalt> core methods for managing a pool of L<Bot::Cobalt::IRC::Server> objects.

This role is consumed by L<Bot::Cobalt::Core> to provide the B<Servers> hash 
(keyed on configured context name) and some convenience methods.

=head1 METHODS

All methods take the configured context name as an argument.

=head2 get_irc_context

Retrieve the L<Bot::Cobalt::IRC::Server> object for the specified context.

=head2 get_irc_obj

Retrieve the object for the backend IRC component; this is a convenience 
method that returns the same object as L<Bot::Cobalt::IRC::Server/irc>

=head2 get_irc_casemap

Retrieve the specified context's CASEMAPPING value; this is a 
convenience method that returns the same string as 
L<Bot::Cobalt::IRC::Server/casemap>

=head2 is_connected

Boolean true if the specified context is marked as connected; this is a 
convenience method that returns the same string as 
L<Bot::Cobalt::IRC::Server/connected>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
