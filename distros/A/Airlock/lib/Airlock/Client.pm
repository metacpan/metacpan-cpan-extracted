package Airlock::Client;

# ABSTRACT: OAuth 2.0 device flow client (RFC 8628)

use Moo;
use Airlock::QR;
use Carp qw( croak );
use HTTP::Tiny;
use JSON::MaybeXS;
use Types::Standard qw( CodeRef InstanceOf Str );
use namespace::autoclean;

our $VERSION = '0.001';


has client_id => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has scope => (
  is      => 'ro',
  isa     => Str,
  default => ''
);


has issuer => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_issuer'
);


has device_endpoint => (
  is  => 'lazy',
  isa => Str
);

sub _build_device_endpoint { $_[0]->_discovered('device_authorization_endpoint') }


has token_endpoint => (
  is  => 'lazy',
  isa => Str
);

sub _build_token_endpoint { $_[0]->_discovered('token_endpoint') }


has ua => (
  is  => 'lazy',
  isa => InstanceOf['HTTP::Tiny']
);

sub _build_ua { HTTP::Tiny->new( agent => 'Airlock-Client/'.$VERSION, timeout => 30, verify_SSL => 1 ) }


has on_prompt => (
  is  => 'lazy',
  isa => CodeRef
);

sub _build_on_prompt {
  my ( $self ) = @_;
  return sub {
    my ( $start ) = @_;
    binmode STDERR, ':encoding(UTF-8)';
    print STDERR $self->prompt_text($start);
  };
}


has sleep => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { sleep $_[0] } }
);


has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);


has _discovery => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__discovery {
  my ( $self ) = @_;
  croak __PACKAGE__.'->new needs issuer, or device_endpoint and token_endpoint' unless $self->has_issuer;
  my $url      = $self->issuer =~ s{/+\z}{}r.'/.well-known/openid-configuration';
  my $response = $self->ua->get( $url, { headers => { Accept => 'application/json' } } );
  croak __PACKAGE__.' discovery failed: '.$response->{status}.' '.$response->{reason}.' for '.$url
    unless $response->{success};
  my $data = $self->_decode($response);
  croak __PACKAGE__.' discovery returned no JSON object for '.$url unless %$data;
  croak __PACKAGE__.' discovery is for another issuer: '.$self->_printable( $data->{issuer} // '(none)' )
    unless ( $data->{issuer} // '' ) =~ s{/+\z}{}r eq $self->issuer =~ s{/+\z}{}r;
  return $data;
}

sub _discovered {
  my ( $self, $key ) = @_;
  return $self->_discovery->{$key} // croak __PACKAGE__.' discovery has no '.$key;
}

sub device_grant_type { 'urn:ietf:params:oauth:grant-type:device_code' }

sub start {
  my ( $self ) = @_;
  my $response = $self->_post( $self->device_endpoint, {
    client_id => $self->client_id,
    length $self->scope ? ( scope => $self->scope ) : ()
  } );
  my $data = $self->_decode($response);
  croak __PACKAGE__.'->start failed: '.$self->_reason( $response, $data )
    unless $response->{success} && defined $data->{device_code} && defined $data->{user_code};
  return $data;
}


sub poll {
  my ( $self, $start ) = @_;
  my $interval = $self->_seconds( $start->{interval}, 5 );
  my $deadline = $self->now->() + $self->_seconds( $start->{expires_in}, 600 );
  while ( ( my $left = $deadline - $self->now->() ) > 0 ) {
    $self->sleep->( $interval < $left ? $interval : $left );
    my $response = $self->_post( $self->token_endpoint, {
      grant_type  => $self->device_grant_type,
      device_code => $start->{device_code},
      client_id   => $self->client_id
    } );
    my $data = $self->_decode($response);
    return $data if $response->{success} && defined $data->{access_token};
    my $error = $data->{error} // '';
    next if $error eq 'authorization_pending';
    if ( $error eq 'slow_down' || $response->{status} == 599 ) {
      $interval += 5;
      next;
    }
    croak __PACKAGE__.'->poll failed: '.$self->_reason( $response, $data );
  }
  croak __PACKAGE__.'->poll gave up: the code expired before anyone approved it';
}


sub login {
  my ( $self ) = @_;
  my $start = $self->start;
  $self->on_prompt->($start);
  return $self->poll($start);
}


sub prompt_text {
  my ( $self, $start, %arg ) = @_;
  my $text = 'Open '.$self->_printable( $start->{verification_uri} ).' and enter the code '
    .$self->_printable( $start->{user_code} )."\n";
  return $text unless defined $start->{verification_uri_complete};
  return $text.'Or scan:'."\n".Airlock::QR->new( text => $start->{verification_uri_complete}, quiet => 2 )->terminal(%arg);
}


# A server can send anything. Only a positive whole number of seconds is
# taken; everything else falls back, so a bad value cannot turn the poll loop
# into a busy loop.
sub _seconds {
  my ( $self, $value, $default ) = @_;
  return $default unless defined $value && !ref $value && $value =~ /\A[0-9]{1,9}\z/ && $value > 0;
  return $value + 0;
}

# What the server sent goes to a terminal: nothing but printable ASCII.
sub _printable {
  my ( $self, $text ) = @_;
  $text //= '';
  $text =~ s/[^\x20-\x7E]/?/g;
  return $text;
}

sub _post {
  my ( $self, $url, $form ) = @_;
  return $self->ua->post_form( $url, $form, { headers => { Accept => 'application/json' } } );
}

sub _decode {
  my ( $self, $response ) = @_;
  my $data = eval { decode_json( $response->{content} // '' ) };
  return ref $data eq 'HASH' ? $data : {};
}

sub _reason {
  my ( $self, $response, $data ) = @_;
  return $data->{error}.( defined $data->{error_description} ? ' ('.$data->{error_description}.')' : '' )
    if defined $data->{error} && !ref $data->{error};
  return $response->{status}.' '.( $response->{reason} // '' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Client - OAuth 2.0 device flow client (RFC 8628)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $client = Airlock::Client->new(
      issuer    => 'https://id.example.org/realms/main',
      client_id => 'my-cli',
      scope     => 'openid profile',
    );

    my $token = $client->login;      # prints code and QR to STDERR, then waits
    print $token->{access_token};

=head1 DESCRIPTION

The other side of the device flow: what a command line tool runs to get a
token. It starts the flow, shows the person where to go, polls the token
endpoint at the pace the server sets, and returns the token response.

It speaks plain RFC 8628 and so works against L<Airlock>, Keycloak, and
anything else that implements the grant, including servers that report errors
with status 200.

=head2 client_id

Required. The client identifier registered with the server.

=head2 scope

Scopes to ask for, separated by spaces. Default: none.

=head2 issuer

The issuer URL. When given, the endpoints are read from
C<< <issuer>/.well-known/openid-configuration >>.

=head2 device_endpoint

The device authorization endpoint. Discovered from C<issuer> unless given.

=head2 token_endpoint

The token endpoint. Discovered from C<issuer> unless given.

=head2 ua

The L<HTTP::Tiny> to use. The default verifies TLS certificates. HTTPS needs
L<IO::Socket::SSL>.

=head2 on_prompt

Coderef called with the device authorization response once the flow has
started. The default prints L</prompt_text> to STDERR.

=head2 sleep

Coderef called with the seconds to wait between polls. For tests.

=head2 now

Coderef returning the current epoch. For tests.

=head2 start

    my $start = $client->start;

Begins the flow. Returns the device authorization response: C<device_code>,
C<user_code>, C<verification_uri>, optionally C<verification_uri_complete>,
C<expires_in> and C<interval>. Croaks when the server refuses.

=head2 poll

    my $token = $client->poll($start);

Waits for the approval. Sleeps the interval the server asked for, never past
the lifetime of the code, adds five seconds on every C<slow_down> and on every
connection failure, and returns the token response. Croaks on
C<access_denied>, C<expired_token>, any other error, and when the code's
lifetime runs out.

=head2 login

    my $token = $client->login;

L</start>, the prompt, then L</poll>.

=head2 prompt_text

    print STDERR $client->prompt_text($start);

What to show the person: where to go, the code, and a QR code of
C<verification_uri_complete> when the server sent one. Takes the options of
L<Airlock::QR/terminal>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
