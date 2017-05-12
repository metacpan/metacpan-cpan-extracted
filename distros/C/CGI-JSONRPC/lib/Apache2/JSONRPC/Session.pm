package Apache2::JSONRPC::Session;
use strict;
use Apache2::JSONRPC;
use CGI::JSONRPC::Dispatcher::Session;
use base qw(Apache2::JSONRPC);

1;

sub new {
   my ($class,%args) = @_;
   %args = __PACKAGE__->init_session(%args);
   return bless { dispatcher => $class->default_dispatcher, %args }, $class;
}

sub _generate_sid {
  my ($class,$r) = @_;
  # ok this makes me feel dirty but it's either use the id generate from
  # CGI::Session, roll our own or don't depend on the POST data not getting
  # messed with.  Personally I feel safer using the CGI::Session id generator
  
  # this "borrowed" from CGI::Session::ID::md5 as a middle ground position

  require Digest::MD5;
  my $md5 = new Digest::MD5();
  $md5->add($$ , time() , rand(time) );
   return $md5->hexdigest();
}

sub cgi_session_dsn {
  my $class = shift;
  return "driver:file;serializer:yaml";
}

# should set the args with a 'session' key
sub init_session {
   my ($class,%args) = @_;
   
   require CGI::Session; 
   require CGI::Cookie;

   my $r = $args{request};
   my $id = $class->_have_cookie($r);
   # if $id is undef or somesuch then CGI::Session needs a CGI object (for what
   # reason I don't know).  So in that case we'll buff $id with a session_id we
   # generate
   $id = $class->_generate_sid($r) unless $id;
   my $session;
 
   $session = CGI::Session->new($class->cgi_session_dsn(), $id);  
   $session->flush(); # could be new?
   $args{session} = $session;

   my $cookie = CGI::Cookie->new(-name => 'CGISESSID', -value => $session->id );
   $r->headers_out->add('Set-Cookie', $cookie );

   return %args;      
}

sub _have_cookie {
  my ($self,$r) = @_;
  if(my $cookie_jar = CGI::Cookie->fetch($r)) {
       if($cookie_jar->{CGISESSID}) {
           return $cookie_jar->{CGISESSID}->value;
       }
   }

   return;

}

=pod

=head1 NAME

Apache2::JSONRPC::Session - Dispatcher class for session aware JSONRPC Objects

=head1 SYNOPSIS

package MyDispatch;

use Apache2::JSONRPC::Session;
use base qw(Apache2::JSONRPC::Session);

# optional custom session rebuild
sub init_session {
   my ($class,%args) = @_;
   # ... regenerate session
   $args{session} = $session;
   return %args;
}


=head1 NOTE

The ::Session portions of CGI::JSONRPC are unmaintained and may change or
disappear without notice (probably change...)

=head1 DESCRIPTION

Apache2::JSONRPC::Dispatcher receives JSONRPC class method calls and translates
them into perl object method calls. Here's how it works:

This package works exactly the same as the L<Apache2::JSONRPC> package with the
exception that it calls it's method C<init_session> prior to dispatching the
call.  You should use this method to rebuild the users session.

=head1 FUNCTIONS

Refer the the L<Apache2::JSONRPC> for a full discussion of this API, only the
extentions to that interface will be discusses here.

=over

=item init_session(%arguments)

Will be called from the constructor just prior to creating the dispatcher object.
C<%arguments> contains the arguments passed into the C<dispatch> or C<new> method
and should be modified and returned as the resulting hash will be blessed and
returned from new.  Rebuild sessions should be stored into the passed hash with 
the key C<session>.

Note that the request object should alreday be stored into the C<%arguments>
variable for your use in rebuilding the session.

=back

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples/httpd.conf" file bundled with the distribution shows how to
create a new JSONRPC::Dispatcher-compatible class, and also shows a rather
hacky method for making an existing class accessable from JSON.

L<Apache2::JSONRPC>

=cut

