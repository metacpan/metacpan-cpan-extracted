package CGI::JSONRPC::Session::Obj;
use strict;

our @IGNORE_KEYS = qw( _session _cgi _request );

1;

sub jsonrpc_new {
    my($class, $dispatcher, $id, $session,%options) = @_;
    warn __PACKAGE__ . " requires a valid session object.  Persistance will not be possible.";
    my $session_key = "jsonrpc_$id";
    if ($session and my $data = $session->param($session_key)) {
      my $self = $class->_jsonrpc_restore($data);
      $self->{_session} = $session;
      $self->{id} = $id unless $self->{id};
      $self->{_session_key} = $session_key;
      $self->{jsonrpc_ignore_keys} = [@IGNORE_KEYS];
      return $self;
      #return bless $self, $class;
    } else {
      return bless { id => $id,_session => $session, _session_key => $session_key, jsonrpc_ignore_keys => [@IGNORE_KEYS], dispatcher => $dispatcher }, $class;
    }
}

# responsible for preparing the self object for serialization
sub _jsonrpc_finish {
  my $self = shift;
  my $session = $self->session();
  if ($session) {
    $session->param($self->{_session_key},$self->_jsonrpc_serialize());
    $session->flush();
  }
}

sub _jsonrpc_restore {
  my ($class,$data) = @_;
  return $data;
}

sub _jsonrpc_serialize {
  our $self = shift;
  delete($self->{_cgi});
  delete($self->{_request});
  delete($self->{_session});
  return $self;
}

sub session {
    my $self = shift;
    return $self->{_session} if $self->{_session};
    return;
}

sub param {
    my $self = shift;
    my $session;
    return $session()->param(@_) if $session = $self->session();
    return;
}

sub flush {
    my $self = shift;
    my $session;
    return $session()->flush() if $session = $self->session();
}

sub jsonrpc_js_name {
    my $class = shift;
    $class = ref($class) if ref($class);
    $class =~ s/::/\./g;
    return $class;
}

sub jsonrpc_javascript {
  my $self = shift;
  return '';
}


=pod

=head1 NAME

CGI::JSONRPC::Session::Obj - Base class for easy handler creation

=head1 SYNOPSIS

  package MyHandler;
  use CGI::JSONRPC::Session::Obj;

  sub jsonrpc_javascript {
    my $js;
     # construct javascript object
    return 
  }
  
  sub do_something {
    $self->{count}++; # count will increment
    my $ac = $self->param('another_count');
    $self->param('another_count',$ac++);
    # handler that jsonrpc will call... 
  }
 

=head1 DESCRIPTION

CGI::JSONRPC::Session::Obj is a base class you can use to ease the creation
of sessioned object handlers.  Although it's fairly trivial to roll your own
we recommend that all handlers use this class for forward compatablity
reasons.

This object can all be viewed as documenting and defining the behaviour
required of all session objects served via CGI::JSONRPC.

=head1 INTERACTION WITH DISPATCHER

When a CGI::JSONRPC::Session call is dispatched the following happens:

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

=item jsonrpc_new($id,$session)

Constructs the jsonrpc_object and inititializes it from the passed id
if appropriate from the passed L<CGI::Session> object.  By default 
all data stored in the object without a leading underscore will be 
serialized and made available between dispatches.

=item jsonrpc_javascript

Should return the javascript that is the javascript expression of this
object. By default this returns the empty string.

=item jsonrpc_js_name 

Convenience method that returns a javascript safe expression of this
objects class.  Never called by the dispatcher but can be used to 
generate the name to be passed in the  I<class> argument in subsequent 
L<CGI::JSONRPC> calls.

=item _jsonrpc_restore($data)

Will be passed the data that was saved as a result of a previous
C<_jsonrpc_serialize> call.  Should return the restored object.

=item _jsonrpc_serialize

Should return a reference to the state that will be needed to restore
this object.  By default this method removes some internal keys from
the self object and returns it.

=item _jsonrpc_finish

Will be called after the dispatch has completed.  Will by default call 
the C<_jsonrpc_serialze> method, store the result into it's session and
flush the it.

=item session

Convenience wrapper that returns the value of the configured session object

=item param

Convenience wrapper that passes any arguments to the configured session object.

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


