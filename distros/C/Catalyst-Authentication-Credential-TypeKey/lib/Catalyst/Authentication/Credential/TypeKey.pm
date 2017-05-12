package Catalyst::Authentication::Credential::TypeKey;
use Catalyst::Exception;
use Authen::TypeKey;
use Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr SimpleStr/;
use namespace::autoclean;

our $VERSION = '0.005';

has [qw/ key_url version /] => (
    isa      => NonEmptySimpleStr,
    is       => 'ro',
    required => 1,
);

has [qw/ key_cache skip_expiry_check /] => (
    isa      => NonEmptySimpleStr,
    is       => 'ro',
    required => 0,
);

has _authen_typekey => (
    is      => 'ro',
    isa     => 'Authen::TypeKey',
    lazy    => 1,
    builder => '_build__authen_typekey',
);

sub _build__authen_typekey {
    my ( $self ) = @_;
    my $tk = Authen::TypeKey->new();
    foreach my $name ( 'key_url', 'version',
                       'key_cache', 'skip_expiry_check' ) {
        $tk->$name( $self->$name ) if $self->$name;
    }
    return $tk;
}

sub BUILDARGS {
    my ( $class, $config, $app, $realm ) = @_;
    unless ( $config->{version} and $config->{key_url} ) {
        Catalyst::Exception->throw(
            __PACKAGE__ . " credential for realm " . $realm->name . " missing version and key_url"
        );
    }
    return $config;
}

=head1 NAME

Catalyst::Authentication::Credential::TypeKey - TypeKey authentication
(in new Catalyst Authentication )

=head1 VERSION

Version 0.005

=head1 SYNOPSIS

Authenticate Catalyst apps with TypeKey system.

Uses the Catalyst::Plugin::Authentication system.
  In MyApp.pm

  use Catalyst qw(
    ...
    Authentication
    ...
  );

  __PACKAGE__->config(
    'authentication' => {
      typekey => {
        credential => {
              class             => 'TypeKey',
              #Config below relies heavly on Authen::TypeKey
              key_cache         => '/var/cache/webapp/myapp/',
              version           => '1',
              skip_expiry_check => '1',
              key_url           => 'http://www.typekey.com/extras/regkeys.txt',
        },
        ...
      },
    },
  );


  In your controller

  sub login : Local {
    # body...
     if ( $c->authenticate( { email => $c->req->param('email') }, 'typekey') ) {
        # SUCCESS
     } else {
        # FAILED
     }
  }


=head1 TODO

=head1 METHODS

=cut

=head1 SEE ALSO

L<Authen::TypeKey>, L<Catalyst>, L<Catalyst::Plugin::Authentication>.

=head1 AUTHOR

zdk

The idea was from https://github.com/omega/catalyst-authentication-credential-typekey

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut


=head2 authenticate

Standard authentication method

=cut

sub authenticate {
    my ( $self, $c, $realm, $auth_info ) = @_;

    my $res = $self->_authen_typekey->verify( $c->req );

    if (! $res ) {
        $c->log->debug( $self->_authen_typekey->errstr ) if $c->debug;
        return;
    }

    $c->model( $realm->{store}->{config}->{user_class} )->find_or_create( $auth_info );

    return unless $auth_info;
    my $user =  $realm->find_user( $auth_info, $c );
    unless ( $user ) {
        $c->log->error('Authenticated user, but could not locate in our Store!');
        return;
    }
    return $user;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
