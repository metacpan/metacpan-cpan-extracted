package Async::Hooks;
{
  $Async::Hooks::VERSION = '0.16';
}

# ABSTRACT: Hook system with asynchronous capabilities

use Mo qw(is default);
use Carp 'confess';
use Async::Hooks::Ctl;
use namespace::clean;


has registry => (
  is      => 'ro',
  default => sub { {} },
);


sub hook {
  my ($self, $hook, $cb) = @_;

  confess("Missing first parameter, the hook name, ") unless $hook;
  confess("Missing second parameter, the coderef callback, ")
    unless ref($cb) eq 'CODE';

  my $cbs = $self->{registry}{$hook} ||= [];
  push @$cbs, $cb;

  return;
}


sub has_hooks_for {
  my ($self, $hook) = @_;

  confess("Missing first parameter, the hook name, ") unless $hook;

  my $reg = $self->{registry};
  return 0 unless exists $reg->{$hook};
  return scalar(@{$reg->{$hook}});
}


sub call {
  my ($self, $hook, $args, $cleanup) = @_;
  ($args, $cleanup) = (undef, $args) if ref($args) eq 'CODE' && !$cleanup;

  confess("Missing first parameter, the hook name, ") unless $hook;
  confess("Second parameter, the arguments list, must be a arrayref, ")
    if $args && ref($args) ne 'ARRAY';
  confess("Third parameter, the cleanup callback, must be a coderef, ")
    if $cleanup && ref($cleanup) ne 'CODE';

  my $r = $self->{registry};
  my $cbs = exists $r->{$hook} ? $r->{$hook} : [];

  return Async::Hooks::Ctl->new([@$cbs], $args, $cleanup)->next;
}


1;    # End of Async::Hooks


__END__
=pod

=head1 NAME

Async::Hooks - Hook system with asynchronous capabilities

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use Async::Hooks;

    my $nc = Async::Hooks->new;

    # Hook a callback on 'my_hook_name' chain
    $nc->hook('my_hook_name', sub {
      my ($ctl, $args) = @_;
      my $url = $args->[0];

      # Async HTTP get, calls sub when it finishes
      http_get($url, sub {
        my ($data) = @_;

        return $ctl->done unless defined $data;

        # You can use unused places in $args as a stash
        $args->[1] = $data;

        $ctl->next;
      });
    });

    $nc->hook('my_hook_name', sub {
      my ($ctl, $args) = @_;

      # example transformation
      $args->[1] =~ s/(</?)(\w+)/"$1".uc($2)/ge;

      $ctl->next;
    });

    # call hook with arguments
    $nc->call('my_hook_name', ['http://search.cpan.org/']);

    # call hook with arguments and cleanup
    $nc->call('my_hook_name', ['http://search.cpan.org/'], sub {
      my ($ctl, $args, $is_done) = @_;

      if (defined $args->[1]) {
        print "Success!\n"
      }
      else {
        print "Oops, could not retrieve URL $args->[0]\n";
      }
    });

=head1 DESCRIPTION

This module allows you to create hooks on your own modules that other
developers can use to extend your functionality, or just react to
important state modifications.

There are other modules that provide the same functionality (see
L<SEE ALSO> section). The biggest diference is that you can pause
processing of the chain of callbacks at any point and start a
asynchronous network request, and resume processing when that request
completes.

Developers are not expect to subclass from C<Async::Hooks>. The
recomended usage is to stick a C<Async::Hooks> instance in a slot or as
a singleton for your whole app, and then delegate some methods to it.

For example, using L<Moose|Moose> you can just:

    has 'hooks' => (
      isa     => 'Async::Hooks',
      is      => 'ro',
      default => sub { Async::Hooks->new },
      lazy    => 1,
      handles => [qw( hook call )],
    );

There are two main usages for hooks: notification or delegation of
responsability.

You can define hook points for notification of important events inside
your class. For example, if you where writting a feed aggregator, you
could define a hook for notification of new items.

In some other cases, your module wants to make part of its bussiness
logic extendable or even replaceable. For example, a SMTP server can ask
if a specific mail address is a valid RCPT. All the registered callbacks
would be called and if one of them has a definitive answer she can just
stop the chain. You can even define a default callback to be called at
the end, as a cleanup step.

You don't need to pre-declare or create a hook. Clients of your module
should consult your documentation to discover which hooks to you support
and then they should just call the C<hook()> method. It takes two
parameters: a scalar, the hook name, and a coderef, the callback.

To call the hook chain, you use the C<call()> method. It requires a
scalar, the hook to call, as the first parameter. The second
optional parameter is an arrayref with arguments, or undef. The third
optional argument, a coderef, is a cleanup callback. This callback
will be called at the end of the chain or as soon as some callback
ends the chain.

The callbacks all have a common signature. They receive two parameters.
The first one is a L<Async::Hooks::Ctl|Async::Hooks::Ctl> object, used
to control the chain of callbacks. The second is an arrayref with the
arguments you used when the hook was called. Something like this:

    sub my_callback {
      my ($ctl, $args) = @_;
      ....
    }

A third parameter is passed to the cleanup callback: a C<$is_done> flag,
with a true value if the chain was ended prematurely C<done()> or
C<stop()>.

The callback only has one responsability: decide if you want to decline
processing of this event, or stop processing if we are done with it.
Cleanup callbacks I<MUST> just return.

To do that, callbacks must call one of two methods:
C<< $ctl->decline() >> or C<< $ctl->done() >>. You can also use
C<next()> or C<declined()> as alias to C<decline()>, and C<stop()>
as alias to C<done()>, whatever feels better.

But you can delay that decision. You can start a network request,
asynchronously, and only decide to decline or stop when the response
arrives. For example, if you use the L<AnyEvent::HTTP|AnyEvent::HTTP>
module to make a HTTP request, you could do something like this:

    sub check_server_is_up_cb {
      my ($ctl, $args) = @_;
      my ($url) = @$args;

      http_get($url, sub {
        my ($data, $headers) = @_;

        if (defined $data) {
          push @$args = $data;
          return $ctl->done;
        }

        return $ctl->next;
      });
    }

In this example, we start a HTTP GET, and use a second callback to
process the result. If a sucessful result is found, we stop the chain.

While the HTTP request is being made, your application can keep on
processing other tasks.

=head1 METHODS

=over 4

=item $registry = Async::Hooks->new()

Creates a L<Async::Hooks|Async::Hooks> object that acts as a registry
for hooks.

You can have several object at the same time, independent of each other.

=item $registry->hook($hook_name, \&cb);

Register a callback with a specific hook.

The callback will be called with two parameters: a
L<Async::Hooks::Ctl|Async::Hooks::Ctl> object and an arrayref with
arguments.

=item $registry->call($hook_name [, \@args] [, \&cleanup])

Calls a specific hook name chain. You can optionally provide an arrayref
with arguments that each callback will receive.

The optional cleanup callback will be called at the end of the chain, or
when a callback calls C<< $ctl->done() >>.

=item $count = $registry->has_hooks_for($hook);

Returns the number of callbacks registered with C<$hook>.

=back

=head1 SEE ALSO

There are a couple of modules that do similar things to this one:

=over 4

=item * L<Object::Event|Object::Event>

=item * L<Class::Observable|Class::Observable>

=item * L<Event::Notify|Event::Notify>

=item * L<Notification::Center|Notification::Center>

=back

Of those four, only L<Object::Event|Object::Event> version 1.0 and later
provides the same ability to pause a chain, do some asynchrounous work
and resume chain processing later.

=head1 ACKNOWLEDGEMENTS

The code was inspired by the C<run_hook_chain> and C<hook_chain_fast>
code of the L<DJabberd project|DJabberd> (see the
L<DJabberd::VHost|DJabberd::VHost> module source code). Hat tip to Brad
Fitzpatrick.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

