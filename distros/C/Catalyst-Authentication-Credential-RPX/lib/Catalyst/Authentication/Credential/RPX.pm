use strict;
use warnings;

package Catalyst::Authentication::Credential::RPX;
BEGIN {
  $Catalyst::Authentication::Credential::RPX::AUTHORITY = 'cpan:KENTNL';
}
{
  $Catalyst::Authentication::Credential::RPX::VERSION = '0.10060100';
}

# ABSTRACT: Use JanRain's RPX service for Credentials

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Has::Sugar;
use namespace::autoclean;
use Net::API::RPX;



has 'api_key'     => ( isa => Str,     ro, required, );
has 'base_url'    => ( isa => Str,     ro, predicate => 'has_base_url', );
has 'ua'          => ( isa => Str,     ro, predicate => 'has_ua', );
has 'token_field' => ( isa => Str,     ro, default => 'token' );

has 'last_auth_info' => (
  rw,
  isa       => HashRef,
  init_arg  => undef,
  predicate => 'has_last_auth_info',
  clearer   => 'clear_last_auth_info',
);



has '_config'     => ( isa => HashRef, rw, required, );
has '_app'        => ( isa => Object | ClassName,  rw, required, );
has '_realm'      => ( isa => Object,  rw, required, );
has '_api_driver' => (
  lazy_build, ro,
  isa      => Object,
  init_arg => undef,
  handles  => [qw( auth_info map unmap mappings )],
);


sub BUILDARGS {
  my ( $class, @arg_list ) = @_;
  ## no critic (ProhibitMagicNumbers)
  if ( @arg_list == 3 ) {
    my %args = (
      _config => $arg_list[0],
      _app    => $arg_list[1],
      _realm  => $arg_list[2],
    );
    for ( keys %{ $args{'_config'} } ) {
      $args{$_} = $args{'_config'}->{$_};
    }
    return $class->SUPER::BUILDARGS(%args);
  }
  return $class->SUPER::BUILDARGS(@arg_list);
}


sub _build__api_driver {
  my $self = shift;
  my $conf = { api_key => $self->api_key };
  if ( $self->has_base_url ) {
    $conf->{'base_url'} = $self->base_url;
  }
  if ( $self->has_ua ) {
    $conf->{'ua'} = $self->ua;
  }
  return Net::API::RPX->new($conf);
}


sub authenticate {
	my ( $self, $c, $realm, $authinfo ) = @_;
	my $token_field = $self->token_field;
	my $token;

	unless ( exists $c->req->params->{$token_field} ) {
    	return;
	}

	$token = $c->req->params->{$token_field};

	my $result = $self->authenticate_rpx( { token => $token } );

	if ( exists $result->{'err'} ) {
    	return;
	}

	my $user_obj = $realm->find_user($result, $c);

	if(ref $user_obj)
	{
		return $user_obj;
	}

	return;
}


sub authenticate_rpx {
  my ( $self, @args ) = @_;
  $self->clear_last_auth_info if $self->has_last_auth_info;
  my $result = $self->_api_driver->auth_info(@args);
  $self->last_auth_info($result);
  return $result;
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Catalyst::Authentication::Credential::RPX - Use JanRain's RPX service for Credentials

=head1 VERSION

version 0.10060100

=head1 SYNOPSIS

    use Catalyst qw/ Authentication /;

    package MyApp::Controller::Auth;

    sub login : Local {
        my ( $self , $c ) = @_;
        $c->authenticate();
    }

=head1 CONFIGURATION

    __PACKAGE__->config('Plugin::Authentication' => {
      default_realm => 'RPX_Service',
      realms        => {
        RPX_Service => {
          credential => {
            class => 'RPX',

            # Package Options
            api_key => 'ASDF...',

            # optional fields
            base_url    => 'http://foo.bar.org',
            ua          => 'Firefox',
            token_field => 'token',
          }
        }
      }
    });

=head1 ATTRIBUTES

=head2 api_key Str[ro]*

The API Key for connecting to the RPX server.

=head2 base_url Str[ro]

The URL The RPX server interconnects with.

=head2 ua Str[ro]

The User-Agent String.

=head2 token_field Str[ro] = 'token'

The token to look for in request parameters

=head2 last_auth_info HashRef[rw]X

The results of the last call to C<< ->auth_info >>

=head1 AUTHENTICATION METHODS

=head2 authenticate

=head2 authenticate ( $context, $realm, $authinfo )

    ->authenticate( $context, $realm, $authinfo )

=head2 authenticate_rpx

=head2 authenticate_rpx ( @args )

    ->authenticate_rpx( @args )

=head1 CONSTRUCTOR METHODS

=head2 new

=head2 new ( $config, $app, $realm );

This method is called by the Authentication API.

    ->new( $config , $app , $realm );

=head1 ATTRIBUTE METHODS

=head2 has_base_url <- predicate('base_url')

=head2 has_ua <- predicate('ua')

=head2 has_last_auth_info <- predicate('last_auth_info')

=head2 clear_last_auth_info <- clearer('last_auth_info')

=head2 auth_info <- _api_driver

=head2 map <- _api_driver

=head2 C<unmap> <- _api_driver

=head2 mappings <- _api_driver

=head1 PRIVATE ATTRIBUTES

=head2 _config HashRef[rw]*

=head2 _app Object|ClassName [rw]*

=head2 _realm Object[rw]*

=head2 _api_driver Object[ro]

=head1 PRIVATE BUILDERS

=head2 _build__api_driver

Creates an instance of L<< C<Net::API::RPX>|Net::API::RPX >> for us to communicate with.

    ->_build__api_driver

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by 'Cloudtone Studios'.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

