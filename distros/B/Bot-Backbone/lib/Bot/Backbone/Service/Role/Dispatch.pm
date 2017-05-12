package Bot::Backbone::Service::Role::Dispatch;
$Bot::Backbone::Service::Role::Dispatch::VERSION = '0.161950';
use v5.10;
use Moose::Role;

with 'Bot::Backbone::Service::Role::SendPolicy';

use namespace::autoclean;

# ABSTRACT: Role for services that can perform dispatch


has dispatcher_name => (
    is          => 'rw',
    isa         => 'Str',
    init_arg    => 'dispatcher',
    predicate   => 'has_dispatcher',
);


has dispatcher => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Dispatcher',
    init_arg    => undef,
    lazy_build  => 1,
    predicate   => 'has_setup_the_dispatcher', 
);

sub _build_dispatcher {
    my $self = shift;

    # If a named dispatcher is given use that
    if ($self->has_dispatcher) {
        return $self->bot->meta->dispatchers->{ $self->dispatcher_name };
    }

    # If we have a dispatch builder
    elsif ($self->meta->has_dispatch_builder) {
        $self->dispatcher_name('<service_dispatcher>');
        return $self->meta->run_dispatch_builder;
    }

    # Use an empty dispatcher
    else {
        $self->dispatcher_name('<empty>');
        return Bot::Backbone::Dispatcher->new;
    }
}


has commands => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    predicate   => 'has_custom_commands',
    traits      => [ 'Hash' ],
    handles     => {
        command_map => 'elements',
    },
);


sub _apply_command_rewrite {
    my $self = shift;
    my %commands = reverse $self->command_map;

    my $iterator = $self->dispatcher->predicate_iterator;
    while (my $predicate = $iterator->next_predicate) {
        if ($predicate->isa('Bot::Backbone::Dispatcher::Predicate::Command')) {
            if ($commands{ $predicate->match }) {
                $predicate->match( $commands{ $predicate->match } );
            }
        }
    }
}

sub BUILD {
    my $self = shift;

    $self->_apply_command_rewrite if $self->has_custom_commands;
}


sub dispatch_message {
    my ($self, $message) = @_;

    if ($self->has_dispatcher) {
        $self->dispatcher->dispatch_message($self, $message);
    }
}


before initialize => sub {
    my $self = shift;
    $self->dispatcher;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::Dispatch - Role for services that can perform dispatch

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

Any service that can use a dispatcher employ this role to make that happen.

=head1 ATTRIBUTES

=head2 dispatcher_name

  dispatcher default => as {
      ...
  };

  service some_service => (
      service    => '=My::Service',
      dispatcher => 'default',
  );

During construction, this is named C<dispatcher>. This is the name of the
dispatcher to load from the bot during initialization.

=head2 dispatcher

  my $dispatcher = $service->dispatcher;

Do not set this attribute. It will be loaded using the L</dispatcher_name>
automatically. It returns a L<Bot::Bakcbone::Dispatcher> object to use for
dispatch.

A C<dispatch_message> method is also delegated to the dispatcher.

=head2 commands

This is an optional setting for any dispatched service. Sometimes it is nice to use the same service more than once in a given context, but that does not work well when the service uses a fixed set of commands. This allows the commands to be remapped. It may also be that a user simply doesn't like the names originally chosen and this lets them change the names of any command.

This attribute takes a reference to a hash of strings which are used to remap the commands. The keys are the new commands to use and the values are the commands that should be replaced. A given command can only be renamed once.

For example,

  service roll => (
      service  => 'OFun::Roll',
      commands => {
          '!rolldice' => '!roll',
          '!flipcoin' => '!flip',
      },
  );

Using the L<Bot::Backbone::Service::OFun::Roll> service, This would rename the C<!roll> command to C<!rolldice> and C<!flip> to C<!flipcoin>. In this case, using C<!roll> in a chat with the bot would no longer have any effect on the service named "roll", but C<!rolldice> would report the outcome of a dice roll.

If this does not provide enough flexibility, you can always go the route of completely replacing a service dispatcher with a new one (and you may want to check out L<Bot::Backbone/respond_by_service_method> and L<Bot::Backbone/run_this_service_method> for help doing that from the bot configuration). You can also define custom code to use L<Bot::Backbone::Dispatcher/predicate_iterator> that walks the entire dispatcher tree and makes changes as needed, which is how this is implemented internally.

=head1 METHODS

=head2 BUILD

Rewrites the dispatcher according to the commands renamed in L</commands>.

=head2 dispatch_message

  $service->dispatch_message($message);

If the service has a dispatcher configured, this will call the L<Bot::Backbone::Dispatcher/dispatch_message> method on the dispatcher.

=head2 initialize

Make sure the dispatcher is initialized by initialization.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
