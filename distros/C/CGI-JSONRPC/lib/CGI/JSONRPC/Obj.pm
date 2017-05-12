package CGI::JSONRPC::Obj;
use strict;

1;

sub jsonrpc_new {
    my($class, $id, $dispatcher) = @_;
    return bless { id => $id, dispatcher => $dispatcher }, $class;
}

sub jsonrpc_js_name {
    my $class = shift;
    $class = ref($class) if ref($class);
    $class =~ s/::/\./g;
    return $class;
}

sub js_class {
   my $self = shift;
   my $name = shift || $self->jsonrpc_js_name(); 
   return '';
}

sub jsonrpc_javascript {
  my $self = shift;
  return $self->js_class
}



=pod

=head1 NAME

CGI::JSONRPC::Obj - Base class for easy handler creation

=head1 SYNOPSIS

  package MyHandler;
  use CGI::JSONRPC::Obj;

  sub jsonrpc_javascript {
    my $js;
     # construct javascript object
    return 
  }
  
  sub do_something {
    # handler that jsonrpc will call... 
  }
 

=head1 DESCRIPTION

CGI::JSONRPC::Obj is a base class you can use to ease the creation
of object handlers.  Although it's fairly trivial to roll your own
we recommend that all handlers use this class for forward compatablity
reasons.

This object can all be viewed as documenting and defining the behaviour
required of all objects served via CGI::JSONRPC.

=head1 INTERACTION WITH DISPATCHER

When a CGI::JSONRPC call is dispatched the following happens:

=over

=item dispatcher creates object

The dispatcher calls the I<jsonrcp_new> method for you object passing
the id value recieved from javascript.  

=item dispatcher calls method

The dispatcher will then call your method passing in the arguments recieved
in the call.

=item GET request

The dispatcher will return the output of the json_javascript method.

=back


=head1 METHODS

=over

=item jsonrpc_new($id)

Constructs the jsonrpc_object and inititializes it from the passed id
if appropriate.  By default there is no serialization of objects so it
is the sole responsibility of all base classes to implement it. 
(see L<CGI::JSONRPC::Obj::Session> for an example)

=item jsonrpc_javascript

Should return the javascript that is the javascript expression of this
object. By default this returns the empty string.

=item jsonrpc_js_name 

Convenience method that returns a javascript safe expression of this
objects class.  Never called by the dispatcher but can be used to 
generate the name to be passed in the  I<class> argument in subsequent 
L<CGI::JSONRPC> calls.

=back

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>.

A lot of the JavaScript code was borrowed from Ingy döt Net's
L<Jemplate|Jemplate> package.

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples" directory (examples/httpd.conf and examples/hello.html),
L<JSON::Syck>, L<http://www.json-rpc.org/>.

=cut

