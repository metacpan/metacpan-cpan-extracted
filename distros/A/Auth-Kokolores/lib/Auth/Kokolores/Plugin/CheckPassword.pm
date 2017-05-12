package Auth::Kokolores::Plugin::CheckPassword;

use Moose;

# ABSTRACT: kokolores plugin for checking passwords
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

has 'method' => ( is => 'ro', isa => 'Str', default => 'plain' );
has 'method_from' => ( is => 'ro', isa => 'Maybe[Str]' );

sub get_method {
  my ( $self, $r ) = @_;
  if( defined $self->method_from ) {
    return $r->get_info( $self->method_from );
  }
  return $self->method;
}

has 'password_from' => ( is => 'ro', isa => 'Str', required => 1 );

sub get_password {
  my ( $self, $r ) = @_;
  return $r->get_info( $self->password_from );
}

has 'cost' => ( is => 'ro', isa => 'Int', default => 1 );
has 'cost_from' => ( is => 'ro', isa => 'Maybe[Str]' );

sub get_cost {
  my ( $self, $r ) = @_;
  if( defined $self->cost_from ) {
    return $r->get_info( $self->cost_from );
  }
  return $self->cost;
}

has 'salt' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'salt_from' => ( is => 'ro', isa => 'Maybe[Str]' );
sub get_salt {
  my ( $self, $r ) = @_;
  if( defined $self->salt_from ) {
    return $r->get_info( $self->salt_from );
  }
  return $self->salt;
}

has 'supported_methods' => (
  is => 'ro', isa => 'ArrayRef[Str]',
  default => sub { [ 'plain' ] },
  traits => [ 'Array' ],
  handles => {
    add_supported_method => 'push',
  },
);

sub is_supported_method {
  my ( $self, $method ) = @_;
  if( grep { $method eq $_ } @{$self->supported_methods} ) {
    return 1;
  }
  return 0;
}

has 'additional_methods' => (
  is => 'ro', isa => 'HashRef[Str]',
  default => sub { {
    pbkdf2 => 'Crypt::PBKDF2',
    bcrypt => 'Crypt::Eksblowfish::Bcrypt',
    bcrypt_fields => 'Digest::Bcrypt',
  } },
);

sub load_additional_methods {
  my $self = shift;
  my $am = $self->additional_methods;

  foreach my $method ( keys %$am ) {
    my $module = $am->{$method};
    eval "require $module;"; ## no critic
    if( $@ ) {
      $self->log(1, "method $method not available. (install ".$am->{$method}.')');
      next;
    }
    $self->add_supported_method( $method );
  }

  return;
}

sub init {
  my ( $self ) = @_;
  $self->load_additional_methods();
  $self->log(2, 'supported password methods: '.join(', ', @{$self->supported_methods}));
  return;
}

sub authenticate {
  my ( $self, $r ) = @_;

  my $method = $self->get_method( $r );
  if( ! defined $method ) {
    $self->log(1, 'no password method defined');
    return 0;
  } elsif( $self->is_supported_method( $method ) ) {
    my $call = "authenticate_$method";
    return $self->$call( $r );
  } else {
    $self->log(1, 'unsupported password method: '.$method);
  }

  return 0;
}

sub authenticate_plain {
  my ( $self, $r ) = @_;
  my $pw = $self->get_password( $r );

  if( $r->password eq $pw ) {
    return 1;
  }
  return 0;
}

has 'pbkdf2' => (
  is => 'ro', isa => 'Crypt::PBKDF2', lazy => 1,
  default => sub { Crypt::PBKDF2->new },
);

sub authenticate_pbkdf2 {
  my ( $self, $r ) = @_;
  my $hash = $self->get_password( $r );

  if( $self->pbkdf2->validate($hash, $r->password) ) {
    return 1;
  }
  return 0;
}

sub authenticate_bcrypt {
  my ( $self, $r ) = @_;
  my $hash = $self->get_password( $r );
  my $pw = $r->password;

  if( Crypt::Eksblowfish::Bcrypt::bcrypt( $pw, $hash ) eq $hash ) {
    return 1;
  }

  return 0;
}

sub authenticate_bcrypt_fields {
  my ( $self, $r ) = @_;
  my $hash = $self->get_password( $r );
  my $pw = $r->password;

  my %params = (
    cost => $self->get_cost($r),
    salt => $self->get_salt($r),
  );
  foreach my $param ( 'cost', 'salt' ) {
    if( ! defined $params{$param} ) {
      $self->log(1, "parameter $param is not defined");
      return 0;
    }
  }

  my $bcrypt = Digest::Bcrypt->new( %params );
  $bcrypt->add( $pw );

  my $hashlen = length( $hash );
  if( $hashlen == 31
      && $pw eq $bcrypt->b64digest ) {
    return 1;
  } elsif( $hashlen == 46
      && $pw eq $bcrypt->hexdigest ) {
    return 1;
  } elsif( $hashlen == 23
      && $pw eq $bcrypt->digest ) {
    return 1;
  }

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::CheckPassword - kokolores plugin for checking passwords

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
