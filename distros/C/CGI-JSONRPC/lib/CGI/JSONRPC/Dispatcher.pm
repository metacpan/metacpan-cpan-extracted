#!perl

package CGI::JSONRPC::Dispatcher;

use strict;
use warnings;
our $AUTOLOAD;
use Attribute::Handlers;
use attributes;

our %Protected;

return 1;

sub UNIVERSAL::DontDispatch :ATTR(CODE) {
  my($package, $symbol) = @_;
  $CGI::JSONRPC::Dispatcher::Protected{$package}{*{$symbol}{NAME}}++;
  return 1;
}

sub DISPATCH_OBJECT {
  my($class, $to) = @_;

}

sub AUTOLOAD {
  my($class, $id, $to) = splice(@_, 0, 3);
  (my $method_name = $AUTOLOAD) =~ s{^.*::}{};
  die "Can't call a $method_name without a class\n" unless $to;
  $to =~ s{[\./]}{::}g;
  die "$to\::$method_name may not be dispatched\n" if $Protected{$to}{$method_name};
  my $object = $to->jsonrpc_new($id, $class);
  if(my $method = $object->can($method_name)) {
    return $method->($object, @_);
  } else {
    die qq{Can't locate object method "$method_name" via package "$to"\n};
  }
}

=pod

=head1 NAME

CGI::JSONRPC::Dispatcher - Dispatch JSONRPC requests to objects

=head1 SYNOPSIS

package Hello;

sub jsonrpc_new {
    my($class, $id) = @_;
    my $self = bless { id => $id }, $class;
}

sub hi {
    return "hey";
}

=head1 DESCRIPTION

Apache2::JSONRPC::Dispatcher receives JSONRPC class method calls and translates
them into perl object method calls. Here's how it works:

=head1 FUNCTION

=over

=item AUTOLOAD($jsonrpc_object, $id, $desired_class, @args)

When any function is called in Apache2::JSONRPC::Dispatcher, the
C<AUTOLOAD> sub runs.

=over

=item *

C<$desired_class> has all of it's dots (.) converted to double-colons (::)
to translate JavaScript class names into perl.

=item *

The C<jsonrpc_new> method in the resulting class is called with
$id passed in as the first argument. An object should be returned from
C<jsonrpc_new> in your code.

=item *

The returned object has the desired method invoked, with any remaining
arguments to AUTOLOAD passed in.

=back

If jsonrpc_new does not exist in the requested package, a fatal error
will occur. This both provides you with a handy state mechanism, and ensures
that packages that aren't supposed to be accessed from the web aren't.

L<Apache2::JSONRPC> attempts to call dispatchers with this set of arguments,
and then takes any return values, serializes them to JSON, and sends a response
back to the client.

=head1 PROTECTING METHODS

If there are any methods in your RPC objects that shouldn't be called from
the web, you can prevent the dispatcher from allowing them by adding the
"DontDispatch" attribute, like so:

  package Authenticator;

  sub get_password : DontDispatch {
    [... code the web shouldn't be able to run goes here...]
  }

Note that if you subclass your RPC classes (not always the best approach,
but it happens sometimes...) you'll have to protect the method in all your
subclasses as well (for now):

  package Authenticator::Child;
  sub get_password : DontDispatch {
    my $self = shift;
    $self->SUPER::get_password(@_);
  }

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>

=head1 LICENSE

Copyright 2008 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples/httpd.conf" file bundled with the distribution shows how to
create a new JSONRPC::Dispatcher-compatible class, and also shows a rather
hacky method for making an existing class accessable from JSON.

L<Apache2::JSONRPC>

=cut
