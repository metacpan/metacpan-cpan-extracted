package Catalyst::Plugin::Authentication::Credential::TypeKey;
use base qw/Class::Accessor/;

use strict;
use warnings;

use Authen::TypeKey;
use File::Spec;
use Catalyst::Utils ();
use NEXT;
use Scalar::Util ();
use Storable     ();
use Carp qw/croak/;

our $VERSION = '0.4';

# Authen::TypeKey's configuration parameters
# FIXME these might change in future versions of Authen::Typekey
my @typekey_config_fields = qw/
  expires key_cache key_url token
  version skip_expiry_check
  /;

# our configuration parameters
# typekey_object is missing for a reason - it has defaulting behavior
my @config_fields = qw/user_class auth_store/;

__PACKAGE__->mk_accessors(qw/last_typekey_object/);

sub setup {
    my $c = shift;

    my $config = $c->config->{authentication}{typekey} ||= {};

    $config->{user_class} ||= "Catalyst::Plugin::Authentication::User::Hash";
    Catalyst::Utils::ensure_class_loaded( $config->{user_class} );

    $config->{key_cache} ||=
      File::Spec->catfile( Catalyst::Utils::class2tempdir( $c, 1 ),
        'regkeys.txt' );

    $config->{typekey_object} ||= do {
        my $typekey = Authen::TypeKey->new;

        for ( grep { exists $config->{$_} } @typekey_config_fields ) {
            $typekey->$_( $config->{$_} );
        }

        $typekey;
    };

    $c->NEXT::setup(@_);
}

sub _munge_typekey_params {
    my ( $c, @params ) = @_;

    my %ret;

    if ( @params % 2 == 1 ) {

        # either it's a user object or a hash ref of credentials
        # if it's a user object the credentials are pulled out of it
        # otherwise a user will be found/made for the credentials
        if ( Scalar::Util::blessed( $params[0] ) ) {
            my $user = $ret{user_object} = shift @params;

            croak "Attempted to authenticate user object, but "
              . "user doesnt't support 'typekey_credentials'"
              unless $user->supports(qw/typekey_credentials/);

            $ret{credentials} = $user->typekey_credentials;

        } elsif ( @params == 1 and ref( $params[0] ) eq "HASH" ) {
            $ret{credentials} = shift @params;
        } else {
            croak "Invalid parameters";
        }
    }

    # now that @params has been munged if needed we can make it into a hash   
    my %params = @params;

    my $config = $c->config->{authentication}{typekey};

    # separate the rest of our params from Authen::TypeKey's
    foreach my $key (@config_fields) {
        # if it was passed as a parameter then move it to the right place
        $ret{$key} = delete $params{$key} || $config->{$key};
    }

    # separate TypeKey's config from credentials
    # these options override config
    $ret{typekey_config} = {};
    foreach my $key (grep { exists $params{$_} } @typekey_config_fields) {
        $ret{typekey_config}{$key} = delete $params{$key};
    }

    # get the object from config and apply local overrides
    $ret{typekey_object} = delete $params{typekey_object} || $c->get_typekey_object( %{ $ret{typekey_config} } );

    # Authen::TypeKey can also take CGI compatible objects
    if ( keys %params ) {
        $ret{credentials} = \%params;
    } else {
        $ret{credentials} = $c->request if not($ret{credentials}) or not( keys %{ $ret{credentials} } );
    }

    return \%ret;
}

sub get_typekey_object {
    my ( $c, %config ) = @_;

    my $object = $c->config->{authentication}{typekey}{typekey_object};

    if ( keys %config ) {
        $object = Storable::dclone($object);
        $object->$_( $config{$_} ) for keys %config;
    }

    return $object;
}

sub authenticate_typekey {
    my ( $c, @params ) = @_;

    my $params = $c->_munge_typekey_params(@params);

    my $typekey    = $params->{typekey_object};
    my $cred       = $params->{credentials};
    my $user       = $params->{user_object};      # probably undef
    my $user_class = $params->{user_class};
    my $auth_store = $params->{auth_store};

    $c->last_typekey_object($typekey);

    if ( my $res = $typekey->verify($cred) ) {
        $c->log->debug("Successfully authenticated user '$res->{name}'.")
          if $c->debug;

        # if a user object was supplied then it has been verified and we're done

        # if not, try to find one in the auth_store (if any)
        if ( !$user and $auth_store ) {
            $auth_store = $c->get_auth_store($auth_store)
              unless ref $auth_store;
            $user = $auth_store->get_user( $res->{name}, $cred, $res );
        }

        # and as a last resort use user_class to create a temporary one
        $user ||= $user_class->new($res);

        $c->set_authenticated($user);

        return $user;
    } else {
        $c->log->debug(
            sprintf "Failed to authenticate user '%s'. Reason: '%s'",
            (
                Scalar::Util::blessed($cred)
                ? $cred->param("name")
                : $cred->{name}
            ),
            $typekey->errstr
          )
          if $c->debug;

        return;
    }
}

sub last_typekey_error {
    my $c = shift;
    $c->last_typekey_object->errstr;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Authentication::Credential::TypeKey - TypeKey Authentication
for Catalyst.

=head1 SYNOPSIS

    use Catalyst qw/Authentication::Credential::TypeKey/;

    MyApp->config->{authentication}{typekey} = {
        token => 'xxxxxxxxxxxxxxxxxxxx',
    };

    sub foo : Local {
		my ( $self, $c ) = @_;

		if ( $c->authenticate_typekey ) {

		# you can also specify the params manually: $c->authenticate_typekey(
		#	name => $name,
		#	email => $email,
		#	...
		#)

			# successful autentication

			$c->user; # this is set
		}
	}


	sub auto : Private {
		my ( $self, $c ) = @_;

		$c->authenticate_typekey; # uses $c->req

		return 1;
	}

=head1 DESCRIPTION

This module integrates L<Authen::TypeKey> with
L<Catalyst::Plugin::Authentication>.

=head1 METHODS

=head3 authenticate_typekey $user_object, %parameters

=head3 authenticate_typekey %parameters

=head3 authenticate_typekey { ... parameters ... }

=head3 authenticate_typekey

This method performs the actual authentication. It's pretty complicated.

Any configuration field (this plugin's configuration, e.g. C<user_class>, as
well as any L<Authen::TypeKey> configuration fields, e.g. C<token>, etc) can
be in %parameters. This will clone the configured typekey object if needed and
set the fields locally for this call only.

All other fields are assumed to be typekey credentials.

If a user object is provided it will be asked for it's typekey credentials and
then authenticated against the server keys.

If there are no typekey credentials in the paramters or the user object, the
credentials will be taken from C<< $c->request >>.

If a user object exists and is authenticated correctly it will be marked as
authenticated. If no such object exists but C<auth_store> is provided (or
configured) then it will attempt to retrieve a user from that store using the
C<name> typekey credential field. If no C<auth_store> is configured or a user
was not found in that store C<user_class> is used to create a temporary user
using the parameters as fields.

=head3 last_typekey_object

The last typekey object used for authentication. This is useful if you use
overrides or need to check errors.

=head3 last_typekey_error

This is C<< $c->last_typekey_object->errstr >>

=head3 get_typekey_object

=head3 EXTENDED METHODS

=head3 setup

Fills the config with defaults.

=head1 CONFIGURATION

C<<$c->config->{autentication}{typekey}>> is a hash with these fields (all can
be left out):

=over 4

=item typekey_object

If this field does not exist an L<Authen::TypeKey> object will be created based
on the other param and put here.

=item expires

=item key_url

=item token

=item version

See L<Authen::TypeKey> for all of these. If they aren't specified
L<Authen::TypeKey>'s defaults will be used.

=item key_cache

Also see L<Authen::TypeKey>.

Defaults to C<regkeys.txt> under L<Catalyst::Utils/class2tempdir>.

=item auth_store

A store (or store name) to retrieve the user from.

When a user is successfully authenticated it will call this:

	$store->get_user( $name, $parameters, $result_of_verify );

Where C<$parameters> is a the hash reference passed to
L<Authen::TypeKey/verify>, and C<$result_of_verify> is the value returned by
L<Authen::TypeKey/verify>.

C<default_auth_store> will B<NOT> be used automatically, you need to set this
parameter to C<"default"> for that to happen. This is because most TypeKey
usage is not store-oriented.

=item user_class

If C<auth_store> or the default store returns nothing from get_user, this class
will be used to instantiate an object by calling C<new> on the class with the
return value from L<Authen::TypeKey/verify>.

=back

=head1 SEE ALSO

L<Authen::TypeKey>, L<Catalyst>, L<Catalyst::Plugin::Authentication>.

=head1 AUTHOR

Christian Hansen

Yuval Kogman, C<nothingmuch@woobling.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
