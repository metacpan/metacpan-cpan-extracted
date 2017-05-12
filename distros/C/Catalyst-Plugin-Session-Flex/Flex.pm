package Catalyst::Plugin::Session::Flex;

use strict;
use base qw/Class::Data::Inheritable Class::Accessor::Fast/;
use NEXT;
use Apache::Session::Flex;
use Digest::MD5;
use URI;
use URI::Find;

our $VERSION = '0.07';

__PACKAGE__->mk_classdata('_session');
__PACKAGE__->mk_accessors('sessionid');

=head1 NAME

Catalyst::Plugin::Session::Flex - Apache::Flex sessions for Catalyst

=head1 SYNOPSIS

use Catalyst 'Session::Flex';

MyApp->config->{session} = {
    Store => 'File',
    Lock => 'Null',
    Generate => 'MD5',
    Serialize => 'Storable',
    expires => '+1M',
    cookie_name => 'session',
};

=head1 DESCRIPTION

Session management using Apache::Session via Apache::Session::Flex

=head2 EXTENDED METHODS

=head3 finalize

=cut

sub finalize {
  my $c = shift;
  my $cookie_name = $c->config->{session}{cookie_name} || 'session';

  if ( $c->config->{session}->{rewrite} ) {
    my $redirect = $c->response->redirect;
    $c->response->redirect( $c->uri($redirect) ) if $redirect;
  }
  
  if ( my $sid = $c->sessionid ) {
    # Always set the cookie for the session response, even if it already exists,
    # this way we set a new expiration time.
    $c->response->cookies->{$cookie_name} = { 
      value => $sid,

      map {
	((defined($c->config->{session}->{$_})) ? ($_ => $c->config->{session}->{$_}) : ())
       } qw(expires domain path secure),
    };

    if ( $c->config->{session}->{rewrite} ) {
      my $finder = URI::Find->new(
				  sub {
				    my ( $uri, $orig ) = @_;
				    my $base = $c->request->base;
				    return $orig unless $orig =~ /^$base/;
				    return $orig if $uri->path =~ /\/-\//;
				    return $c->uri($orig);
				  }
				 );
      $finder->find( \$c->res->{body} ) if $c->res->body;
    }
  }

  untie(%{$c->{session}});
  delete $c->{session};

  return $c->NEXT::finalize(@_);
}

=head3 prepare_action

=cut

sub prepare_action {
  my $c = shift;
  my $cookie_name = $c->config->{session}{cookie_name} || 'session';
  if ( $c->request->path =~ /^(.*)\/\-\/(.+)$/ ) {
    $c->request->path($1);
    $c->sessionid($2);
    $c->log->debug(qq/Found sessionid "$2" in path/) if $c->debug;
  }
  if ( my $cookie = $c->request->cookies->{$cookie_name} ) {
    my $sid = $cookie->value;
    $c->sessionid($sid);
    $c->log->debug(qq/Found sessionid "$sid" in cookie/) if $c->debug;
  }

  $c->NEXT::prepare_action(@_);  
}

=head3 session_clear

Clear the existing session from storage and create a new session.

=cut

sub session_clear {
  my $c = shift;
  
  if($c->{session}) {
    tied(%{$c->{session}})->delete;
    untie($c->{session});
    delete $c->{session};
  }

  my $session = {};

  eval {
    my $sid;
    tie %{$session}, 'Apache::Session::Flex', undef, $c->config->{session};
    $c->sessionid($sid = $session->{_session_id});
    $c->log->debug(qq/Created session "$sid"/) if $c->debug;
  };
  if($@) {
    die("Failed to create new session");
  }

  return $c->{session} = $session;
}

=head3 session

Return the session as a hash reference.  If a session id was found via a URL or cookie from the client
it will be used to retrieve the data previously stored.  If the previous session id was invalid or
otherwise unretrievable, create a new session.

=cut


sub session {
  my $c = shift;

  return $c->{session} if $c->{session};
  my $sid = $c->sessionid;


  my $session = {};
  if($sid) {
    # Load the session.
    eval {
      tie %{$session}, 'Apache::Session::Flex', $sid, $c->config->{session};
    };
    if($@) {
      # Handle the error where the session couldn't be retrieved.
      $c->sessionid(undef);
      return $c->session();
    }
    return $c->{session} = $session;
  } 
  
  eval {
    tie %{$session}, 'Apache::Session::Flex', undef, $c->config->{session};
    $c->sessionid($sid = $session->{_session_id});
    $c->log->debug(qq/Created session "$sid"/) if $c->debug;
  };
  if($@) {
    die("Failed to create new session");
  }
  # Load in the session id.
  $c->{session} = $session;

  return $c->{session};
}


=head3 setup

=cut

sub setup {
  my $self = shift;
  
  # Load in the sensible defaults for session storage.
  my %defaults = (
		  Store => 'File',
		  Lock => 'Null',
		  Generate => 'MD5',
		  Serialize => 'Storable',

		  # Defaults for the defaults.
		  Directory => '/tmp/session',
		  LockDirectory => '/var/lock/sessions',
		 );

  while(my ($k, $v) = each %defaults) {
    if(!exists($self->config->{session}->{$k})) {
      $self->config->{session}->{$k} = $v;
    }
  }
  
  return $self->NEXT::setup(@_);
}

=head2 METHODS

=head3 session

=head3 uri

Extends an uri with session id if needed.

    my $uri = $c->uri('http://localhost/foo');

=cut

sub uri {
    my ( $c, $uri ) = @_;
    if ( my $sid = $c->sessionid ) {
        $uri = URI->new($uri);
        my $path = $uri->path;
        $path .= '/' unless $path =~ /\/$/;
        $uri->path( $path . "-/$sid" );
        return $uri->as_string;
    }
    return $uri;
}


=head2 CONFIG OPTIONS

All of the options are inheritied from L<Apache::Session::Flex> and
various L<Apache::Session> modules such as L<Apache::Session::File>.

=head3 rewrite

To enable automatic storing of sessions in the url set this to a true value.

=head3 expires

By default, the session cookie expires when the user closes their browser.
To keep a persistent cookie, set an expires config option.  Valid values
for this option are the same as in L<CGI>, i.e. +1d, +3M, and so on.

=head3 domain

Set the domain of the session cookie

=head3 path

Set the path of the session cookie

=head3 secure

If true only set the session cookie if the request was retrieved via HTTPS.

=head3 cookie_name

Specify the name of the session cookie

=head1 SEE ALSO

L<Catalyst> L<Apache::Session> L<Apache::Session::Flex> L<CGI::Cookie>

=head1 AUTHOR

Rusty Conover C<rconover@infogears.com>

Patched by:

Andy Grundman C<andy@hybridized.org>

John Beppu C<beppu@somebox.com>

Based off of L<Catalyst::Plugin::Session::FastMmap> by:

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
