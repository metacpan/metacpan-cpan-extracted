package Auth::Kokolores::Protocol::DovecotAuth;

# read dovecot wiki for protocol specs:
# http://wiki2.dovecot.org/Authentication%20Protocol
# http://wiki2.dovecot.org/Authentication/Mechanisms

use Moose;
extends 'Auth::Kokolores::Protocol';

# ABSTRACT: dovecot auth protocol implementation for kokolores
our $VERSION = '1.01'; # VERSION

use Auth::Kokolores::Request;

use MIME::Base64;

has 'major_version' => ( is => 'ro', isa => 'Int', default => 1 );
has 'minor_version' => ( is => 'ro', isa => 'Int', default => 1 );

has 'client_major_version' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'client_minor_version' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'client_pid' => ( is => 'rw', isa => 'Maybe[Str]' );

sub read_command {
  my ( $self, $expected ) = @_;
  my $line = $self->handle->getline;
  $line =~ s/[\r\n]*$//;
  my @fields = split("\t", $line);
  $self->log(4, 'recv cmd: '.join(', ', @fields));
  if( ! defined $fields[0] ) {
    die('protocol error: no command specified on line');
  }
  if( defined $expected && $fields[0] ne $expected ) {
    die('protocol error: expected command '.$expected.' got '.$fields[0]);
  }
  return @fields;
}

sub send_command {
  my ( $self, @cmd ) = @_;
  $self->log(4, 'send cmd: '.join(', ', @cmd));
  $self->handle->print( join("\t", @cmd)."\n" );
  return;
}

sub init_connection {
  my ( $self ) = @_;
  my ( $cmaj, $cmin, $cpid );
  ( undef, $cmaj, $cmin ) = $self->read_command('VERSION');
  ( undef, $cpid ) = $self->read_command('CPID');
  if( $cmaj ne $self->major_version ) {
    die('wrong major protocol version');
  }
  $self->client_major_version( $cmaj );
  $self->client_minor_version( $cmin );
  $self->client_pid( $cpid );
  $self->send_command('VERSION', $self->major_version, $self->minor_version);
  $self->send_command('SPID', $$);
  foreach my $mech ( keys %{$self->mechanisms} ) {
    $self->send_command('MECH', $mech,
      @{$self->mechanisms->{$mech}->{'parameters'}} );
  }
  $self->send_command('DONE');
  return;
}

sub shutdown_connection {
  my ( $self ) = @_;
  $self->last_auth_id(0);
  return:
}

has 'mechanisms' => (
  is => 'ro', isa => 'HashRef', lazy => 1,
  default => sub { {
    'LOGIN' => {
      parameters => [ 'plaintext '],
      handler => \&handle_login,
    },
    'PLAIN' => {
      parameters => [ 'plaintext '],
      handler => \&handle_plain,
    },
  } },
);

has 'last_auth_id' => ( is => 'rw', isa => 'Int', default => 0 );

sub read_auth_command {
  my $self = shift;
  my $cmd = {};
  my ( undef, $id, $mech, @params ) = $self->read_command('AUTH');

  while( my $p = shift @params ) {
    if( $p =~ /^resp=/ ) { # everything next is resp
      my $resp = join("\t", $p, @params);
      $resp = substr($resp, 5);
      $cmd->{'resp'} = $resp;
      last;
    } elsif( $p =~ /=/ ) {
      my ( $key, $value ) = split('=', $p, 2);
      $cmd->{$key} = $value;
    } else {
      $cmd->{$p} = 1;
    }
  }
  $cmd->{'mech'} = $mech;
  $cmd->{'id'} = $id;
  $self->{'last_auth_id'} = $id;

  return( $cmd );
}

sub _check_auth_id {
  my ( $self, $id ) = @_;
  if( defined $self->last_auth_id
      && $self->last_auth_id ne $id ) {
    die('protocol error: missmatch of AUTH ID');
  }
  return;
}

sub handle_login {
  my ( $self, $cmd ) = @_;
  my ( $id, $username, $password );

  $self->send_command('CONT', $self->last_auth_id,
    encode_base64('Username:'));
  ( undef, $id, $username ) = $self->read_command('CONT');
  $self->_check_auth_id( $id );
  $username = decode_base64( $username );

  $self->send_command('CONT', $self->last_auth_id,
    encode_base64('Password:'));
  ( undef, $id, $password ) = $self->read_command('CONT');
  $self->_check_auth_id( $id );
  $password = decode_base64( $password );

  return($username, $password, $cmd);
}

sub handle_plain {
  my ( $self, $cmd ) = @_;
  if( ! defined $cmd->{'resp'} ) {
    die('protocol error: AUTH PLAIN request without resp= parameter');
  }
  $cmd->{'resp'} = decode_base64( $cmd->{'resp'} );
  my ( $authzid, $authcid, $passwd ) = split("\0", $cmd->{'resp'});
  $cmd->{'authzid'} = $authzid;
  return( $authcid, $passwd, $cmd );
}

sub read_request {
  my $self = shift;

  my $cmd = $self->read_auth_command;
  my $mech = $self->mechanisms->{ $cmd->{'mech'} };
  if( ! defined $mech ) {
    die('mechanism is not supported');
  }
  my ( $username, $password, $params )
    = $mech->{'handler'}->( $self, $cmd );

  return Auth::Kokolores::Request->new(
    username => $username,
    password => $password,
    parameters => $params,
    server => $self->server,
  );
}

sub write_response {
  my ( $self, $response ) = @_;
  my $cmd = 'FAIL';
  if( $response->success ) {
    $cmd = 'OK';
  }

  $self->send_command($cmd, $self->last_auth_id);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Protocol::DovecotAuth - dovecot auth protocol implementation for kokolores

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
