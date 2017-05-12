package CatalystX::ConsumesJMS;
$CatalystX::ConsumesJMS::VERSION = '1.08';
{
  $CatalystX::ConsumesJMS::DIST = 'CatalystX-ConsumesJMS';
}
use Moose::Role;
use namespace::autoclean;
with 'CatalystX::RouteMaster';
use Catalyst::Utils ();

# ABSTRACT: role for components providing Catalyst actions consuming messages



sub _controller_base_classes { 'Catalyst::Controller::JMS' }


sub _action_extra_params {
    my ($self,$c,$destination,$type,$route) = @_;
    return attributes => { MessageTarget => [$type] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::ConsumesJMS - role for components providing Catalyst actions consuming messages

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  package MyApp::Base::MyConsumer;
  use Moose;
  extends 'Catalyst::Component';
  with 'CatalystX::ConsumesJMS';

  sub _kind_name {'MyConsumer'}
  sub _wrap_code {
    my ($self,$c,$destination_name,$msg_type,$route) = @_;
    my $code = $route->{code};
    my $extra_config = $route->{extra_config};
    return sub {
      my ($controller,$ctx) = @_;
      my $message = $ctx->req->data;
      $self->$code($message);
    }
  }

Then:

  package MyApp::MyConsumer::One;
  use Moose;
  extends 'MyApp::Base::MyConsumer';

  sub routes {
    return {
      my_input_destination => {
        my_message_type => {
          code => \&my_consume_method,
          extra_config => $whatever,
        },
        ...
      },
      ...
    }
  }

  sub my_consume_method {
    my ($self,$message) = @_;

    # do something
  }

Also, remember to tell L<Catalyst> to load your C<MyConsumer> components:

  <setup_components>
   search_extra [ ::MyConsumer ]
  </setup_components>

=head1 DESCRIPTION

This role is to be used to define base classes for your Catalyst-based
JMS / STOMP consumer applications. It's I<not> to be consumed directly
by application components. See L<CatalystX::RouteMaster> for
implementation details and a rationale. Most of the rest of this
document is copied from there.

=head2 Routing

Subclasses of your component base specify which messages they are
interested in, by writing a C<routes> sub, see the synopsis for an
example.

They can specify as many destinations and message types as they want /
need, and they can re-use the C<code> values as many times as needed.

The main limitation is that you can't have two components using the
exact same destination / type pair (even if they derive from different
base classes!). If you do, the results are undefined.

It is possible to alter the destination name via configuration, like:

  <MyConsumer::One>
   <routes_map>
    my_input_destination the_actual_destination_name
   </routes_map>
  </MyConsumer::One>

You can also do this:

  <MyConsumer::One>
   <routes_map>
    my_input_destination the_actual_destination_name
    my_input_destination another_destination_name
   </routes_map>
  </MyConsumer::One>

to get the consumer to consume from two different destinations without
altering the code.

You can even alter the message type via the configuration:

  <MyConsumer::One>
   <routes_map>
    <my_input_destination the_actual_destination_name>
      my_message_type actual_type_1
    </my_input_destination>
    <my_input_destination another_destination_name>
      my_message_type actual_type_2
      my_message_type actual_type_3
    </my_input_destination>
   </routes_map>
  </Stuff::One>

That would install 3 identical actions for the following destination /
message type pairs:

=over 4

=item C<actual_type_1> on C<the_actual_destination_name>

=item C<actual_type_2> on C<another_destination_name>

=item C<actual_type_3> on C<another_destination_name>

=back

=head2 The "code"

The hashref specified by each destination / type pair will be passed
to the L</_wrap_code> function (that the consuming class has to
provide), and the coderef returned will be installed as the action to
invoke when a message of that type is received from that destination.

=head1 Required methods

=head2 C<_kind_name>

As in the synopsis, this should return a string that, in the names of
the classes deriving from the consuming class, separates the
"application name" from the "component name".

These names are mostly used to access the configuration.

=head2 C<_wrap_code>

This method is called with:

=over 4

=item *

the Catalyst application as passed to C<register_actions>

=item *

the destination name

=item *

the message type

=item *

the value from the C<routes> corresponding to the destination name and
message type slot (see L</Routing> above)

=back

You can do whatever you need in this method, but the synopsis gives a
generally useful idea. You can find more examples of use at
L<https://github.com/dakkar/CatalystX-StompSampleApps>

The coderef returned will be invoked as a Catalyst action for each
received message, which means it will get:

=over 4

=item *

the controller instance (you should rarely need this)

=item *

the Catalyst application context

=back

You can get the de-serialized message by calling C<< $c->req->data >>.
The JMS headers will most probably be in C<< $c->req->env >> (or C<<
$c->engine->env >> for older Catalyst), all keys namespaced by
prefixing them with C<jms.>. So to get all JMS headers you could do:

   my $psgi_env = $c->req->can('env')
                  ? $c->req->env
                  : $c->engine->env;
   my %headers = map { s/^jms\.//r, $psgi_env->{$_} }
                 grep { /^jms\./ } keys $psgi_env;

You can set the message to serialise in the response by setting C<<
$c->stash->{message} >>, and the headers by calling C<<
$c->res->header >> (yes, incoming and outgoing data are handled
asymmetrically. Sorry.)

=head2 C<_controller_base_classes>

List (not arrayref!) of class names that the controllers generated by
C<_generate_controller_package> should inherit from. Defaults to
C<'Catalyst::Controller::JMS'>.

=head2 C<_controller_roles>

List (not arrayref!) of role names that should be applied to the
controllers created by C<_generate_controller_package>. Defaults to
the empty list.

=head2 C<_action_extra_params>

  my %extra_params = $self->_action_extra_params(
                      $c,$destination,
                      $message_type,$route->{$message_type},
                     );

You can override this method to provide additional arguments for the
C<create_action> call inside
C<_generate_register_action_modifier>. For example you could return:

  attributes => { MySpecialAttr => [ 'foo' ] }

to set that attribute for all generated actions. Defaults to:

  attributes => { 'MessageTarget' => [$message_type] }

to get L<Catalyst::Controller::JMS> to create an action to which that
message type gets dispatched.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
